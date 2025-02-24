# frozen_string_literal: true

module Jobs
  class MigrateSidekiqScheduledJobs < ::Jobs::Onceoff
    def execute_onceoff(args)
      jobs_to_migrate = Sidekiq::ScheduledSet.new.to_a
      jobs_to_migrate.each do |job|
        Sidekiq::Client.via(Sidekiq.old_pool) do
          Sidekiq::ScheduledSet.new.schedule(job.score, job.item)
        end
      end
      jobs_to_migrate.each(&:delete)
    end
  end
end
