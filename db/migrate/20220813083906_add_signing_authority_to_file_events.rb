class AddSigningAuthorityToFileEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :file_events, :signature_signer, :string
    add_column :file_events, :signature_authorities, :string
    add_column :file_events, :process_arguments, :string
    add_index :file_events, :signature_signer
  end
end
