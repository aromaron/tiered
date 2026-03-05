# frozen_string_literal: true

class CreatePlanPayQuotaStates < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :plan_pay_quota_states do |t|
      t.references :plan_owner, polymorphic: true, null: false
      t.string :quota_key, null: false
      t.datetime :exceeded_at
      t.datetime :blocked_at
      t.decimal :last_warning_threshold
      t.datetime :last_warning_at
      t.json :metadata
      t.timestamps
    end

    add_index :plan_pay_quota_states,
              [:plan_owner_type, :plan_owner_id, :quota_key],
              unique: true,
              name: "index_plan_pay_quota_states_unique"
    add_index :plan_pay_quota_states, [:plan_owner_type, :plan_owner_id]
    # Partial index for exceeded_at (PostgreSQL syntax)
    if connection.adapter_name == "PostgreSQL"
      add_index :plan_pay_quota_states,
                :exceeded_at,
                where: "exceeded_at IS NOT NULL"
    else
      add_index :plan_pay_quota_states, :exceeded_at
    end
  end
end

