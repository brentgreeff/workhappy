class CreateExports < ActiveRecord::Migration[8.1]
  def change
    create_table :exports do |t|
      t.references :company, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "queued"
      t.date :from_date
      t.date :to_date
      t.string :status_filter
      t.integer :row_count
      t.string :error_message

      t.timestamps
    end

    add_check_constraint :exports,
      "status IS NOT NULL AND status IN ('queued', 'processing', 'ready', 'failed')",
      name: "exports_status_allowed"
  end
end
