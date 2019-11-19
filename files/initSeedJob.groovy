pipelineJob('Seed-Job'){
      parameters {
            gitParam('branch') {
            type('BRANCH')
            sortMode('ASCENDING_SMART')
            defaultValue('origin/master')
        }
    }
    definition {
        cpsScm {
            scm {
                git{
                    remote {
                        github("Nightmayr/jenkins-shared-library", "ssh")
                        credentials("github-key")
                    }
                    branch('$branch')
                }
        }
            scriptPath('resources/init/seedJob.groovy')
        }
    }
}
