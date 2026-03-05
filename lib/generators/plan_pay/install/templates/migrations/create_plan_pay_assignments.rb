# frozen_string_literal: true

class CreatePlanPayAssignments < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :plan_pay_assignments do |t|
      t.references :plan_owner, polymorphic: true, null: false
      t.string :plan_key, null: false
      t.string :source, null: false
      t.timestamps
    end

    add_index :plan_pay_assignments, [:plan_owner_type, :plan_owner_id], unique: true
    add_index :plan_pay_assignments, :plan_key
  end
end

