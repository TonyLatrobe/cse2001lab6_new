pipeline {
    agent {
        kubernetes {
            yamlFile 'jenkins/pod-templates/devops.yaml'
            defaultContainer 'ci'
        }
    }

    stages {

        stage('Debug') {
            steps {
                container('ci') {
                    sh '''
                        echo "Debug stage"
                        hostname
                        python --version
                        env | sort
                        ls -la
                    '''
                }
            }
        }

        stage('Unit Tests') {
            steps {
                container('ci') {
                  sh '''
                    echo "Running unit tests"
                    # This tells Python that the 'app' folder contains our packages
                    export PYTHONPATH=$PYTHONPATH:$(pwd)/app
                    pytest app/tests/test_app.py
                  '''
                }
            }
        }

        stage('Build') {
            steps {
                container('ci') {
                    sh '''
                        echo "Build validation"
                        python -m py_compile app/src/app.py
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                container('ci') {
                    sh '''
                        echo "Terraform validation"
                        cd terraform
                        terraform init
                        terraform validate
                    '''
                }
            }
        }

        stage('OPA Policy Check') {
            steps {
                container('ci') {
                    sh '''
                            cd terraform
                            terraform init -input=false
                            terraform plan -out=tfplan
                            terraform show -json tfplan > tfplan.json

                            DENY=$(opa eval --format raw \
                            --data ../app/opa/terraform.rego \
                            --input tfplan.json \
                            "data.terraform.security.deny")

                            echo "OPA deny: $DENY"
                            if [ "$DENY" != "[]" ]; then
                            echo "OPA policy violation! Failing build."
                            exit 1
                            fi

                    '''
                }
            }
        }

        stage('Terraform Security') {
            steps {
                container('ci') {
                  sh '''
                    # 1. Standard Offline Flags
                    export BC_SKIP_MAPPING=true
                    export CKV_SKIP_CHECK_OV_VERSION=true

                    echo "--- Current Directory Check ---"
                    pwd
                    echo "Current Dir: $(pwd)"
                    echo "Jenkins Workspace Env: ${WORKSPACE}"

                    echo "--- Running Checkov Scan ---"
                    # We add --directory . explicitly
                    # We also remove --quiet for a moment so we can see if it skips files
                    checkov -d . --framework terraform dockerfile -o json --soft-fail > checkov.json

                    # 2. Extract Data
                    TOTAL=$(jq '[.[]?.summary? | (.passed + .failed + .skipped)] | add' checkov.json)
                    FAILED=$(jq '[.[]?.summary?.failed] | add' checkov.json)

                    # 3. Handle '0' results by checking if the file is valid JSON
                    if [ "$TOTAL" -eq 0 ]; then
                        echo "DEBUG: checkov.json content below:"
                        cat checkov.json
                        echo "Checkov found 0 files. Ensure your .tf or Dockerfiles are in $(pwd)"
                    fi
                    # Handle the case where TOTAL is still null or 0 to prevent the "out of range" error
                    if [ -z "$TOTAL" ] || [ "$TOTAL" = "null" ] || [ "$TOTAL" -eq 0 ]; then
                        echo "Checkov found no files to scan or the JSON was invalid."
                        TOTAL=0
                        FAILED=0
                        FAILURE_RATE=0
                    else
                        # Calculate failure rate safely
                        FAILURE_RATE=$(echo "scale=2; ($FAILED / $TOTAL) * 100" | bc)
                    fi

                    echo "Total Checks: $TOTAL"
                    echo "Failed Checks: $FAILED"
                    echo "Checkov failure rate: ${FAILURE_RATE}%"

                    # 4. Threshold Logic
                    # Check if FAILURE_RATE > 20
                    THRESHOLD_REACHED=$(echo "$FAILURE_RATE > 20" | bc)
                    if [ "$THRESHOLD_REACHED" -eq 1 ]; then
                        echo "Failure rate too high! Failing build."
                        exit 1
                    fi
                  '''
                }
            }
            post {
                always {
                     archiveArtifacts artifacts: 'checkov.json', fingerprint: true
                }
            }
        }

        stage('Deploy.Run') {
            steps {
                container('ci') {
                sh '''
                  echo "Deploying and Running App"
                  # 1. Move into the 'app' directory so 'src' is visible
                  cd app
                
                  # 2. Set PYTHONPATH to the current directory
                  export PYTHONPATH=.
                
                  # 3. Run using the module flag (-m)
                  # Note: No '.py' extension here!
                  python3 -m src.app 3 5
                '''
                }
            }
        }
    }
}