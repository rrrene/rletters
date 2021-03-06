# -*- encoding : utf-8 -*-

# Send notification e-mails to users
#
# This mailer is responsible for sending e-mails to users when their analysis
# tasks complete.
class UserMailer < ActionMailer::Base
  include Resque::Mailer
  default from: 'noreply@example.com'

  layout 'ink_email'

  # E-mail users that their jobs have finished
  #
  # @api public
  # @param [String] email the address to send the mail
  # @param [String] task_id the ID of the task that just finished
  # @return [void]
  # @example Send a mail to the developers that a task has finished
  #   job_finished_email('rletters@rletters.net', @task.to_param)
  def job_finished_email(email, task_id)
    @task = Datasets::AnalysisTask.find(task_id)

    mail(from: Admin::Setting.app_email,
         to: email,
         task: @task,
         subject: I18n.t('user_mailer.job_finished.subject',
                         app_name: Admin::Setting.app_name))
  end
end
