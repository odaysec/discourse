# frozen_string_literal: true

module Jobs
  class MigrateSidekiqScheduledJobs < ::Jobs::Onceoff
    def execute_onceoff(args)
      jobs_to_migrate = Sidekiq::Client.via(Sidekiq.old_pool) { Sidekiq::ScheduledSet.new.to_a }
      jobs_to_migrate.each { |job| Sidekiq::ScheduledSet.new.schedule(job.score, job.item) }
      Sidekiq::Client.via(Sidekiq.old_pool) { jobs_to_migrate.each(&:delete) }
    end
  end
end
