# frozen_string_literal: true

class CreatePlanPayUsages < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :plan_pay_usages do |t|
      t.references :plan_owner, polymorphic: true, null: false
      t.string :quota_key, null: false
      t.datetime :period_start, null: false
      t.datetime :period_end
      t.bigint :used, default: 0
      t.datetime :last_used_at
      t.timestamps
    end

    add_index :plan_pay_usages,
              [:plan_owner_type, :plan_owner_id, :quota_key, :period_start],
              unique: true,
              name: "index_plan_pay_usages_unique"
    add_index :plan_pay_usages, [:plan_owner_type, :plan_owner_id]
    add_index :plan_pay_usages, [:period_start, :period_end]
  end
end

