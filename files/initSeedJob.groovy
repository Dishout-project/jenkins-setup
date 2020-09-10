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
                        github("Dishout-project/job-definitions", "ssh")
                        credentials("github-key")
                    }
                    branch('$branch')
                }
        }
            scriptPath('resources/init/seedJob.groovy')
        }
    }
}
