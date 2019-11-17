pipelineJob('Seed-Job'){
    definition {
        cpsScm {
            scm {
                git{
                    remote {
                        github("Nightmayr/jenkins-shared-library", "ssh")
                        credentials("github-key")
                    }
                    branch("master")
                }
        }
            scriptPath('resources/init/seedJob.groovy')
        }
    }
}
