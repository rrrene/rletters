# -*- encoding : utf-8 -*-
class CreateAnalysisTaskResults < ActiveRecord::Migration
  def self.up
    create_table :analysis_task_results do |t|
      t.integer    :analysis_task_id
      t.string     :style
      t.binary     :file_contents
    end
  end

  def self.down
    drop_table :analysis_task_results
  end
end
