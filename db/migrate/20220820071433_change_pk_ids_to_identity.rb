class ChangePkIdsToIdentity < ActiveRecord::Migration[7.0]
  def make_query(table, restart)
    """
      ALTER TABLE #{table} ALTER id DROP DEFAULT; -- drop default

      DROP SEQUENCE #{table}_id_seq;              -- drop owned sequence

      ALTER TABLE #{table} ALTER id ADD GENERATED ALWAYS AS IDENTITY
          (RESTART #{restart});
    """
  end

  def change
    [FileEvent, ProcessEvent, Logfile, LogfileLine, MacOsSystemLog].each do |klass|
      restart = (klass.maximum(:id) || 0) + 1
      ActiveRecord::Base.connection.execute(make_query(klass.table_name, restart))
    end
  end
end
