class Compensation
  include DataMapper::Resource

  storage_names[:default] = "chi_lobbyist_compensations"

  property :id,                     Serial,  :required => true
  property :lobbyist_id,            Integer, :required => true
  property :compensation,           Decimal, :default => 0.00, :precision => 15, :scale => 2
  property :client_id,				Integer, :required => true

  belongs_to :lobbyist
  belongs_to :client

  def self.group_lobbyist_compensations default_options={:limit => 5}
    sql = <<-SQL
      SELECT l.slug, l.full_name, SUM(c.compensation)
      FROM chi_lobbyist_compensations c
        INNER JOIN chi_lobbyists l
        ON c.lobbyist_id = l.id
      GROUP BY l.slug, l.full_name
      ORDER BY SUM(c.compensation) DESC
      LIMIT ?
    SQL

    repository(:default).adapter.select(sql.strip, default_options[:limit]).map { |struct|
      [struct.slug, struct.full_name, "%.2f" % struct.sum] }
  end

  def self.group_firm_compensations default_options={:limit => 5}
    sql = <<-SQL
      SELECT r.firm_id, f.name, f.slug, SUM(c.compensation)
      FROM chi_lobbyist_firm_relationships r
        RIGHT OUTER JOIN chi_lobbyist_compensations c
        ON r.lobbyist_id = c.lobbyist_id

        LEFT OUTER JOIN chi_firms f
        ON r.firm_id = f.id
      GROUP BY r.firm_id, f.name, f.slug
      ORDER BY SUM(DISTINCT c.compensation) desc
      LIMIT ?
    SQL

    repository(:default).adapter.select(sql.strip, default_options[:limit]).map { |struct|
      [struct.name, struct.slug, "%.2f" % struct.sum] }
  end
  
  def self.compensation_by_lobbyist_by_client default_options={:lobbyist_id => 0, :client_id => 0}
    sql = <<-SQL
      SELECT sum(compensation)
      FROM chi_lobbyist_compensations
      WHERE lobbyist_id = ?
      AND client_id = ?
    SQL

    repository(:default).adapter.select(sql.strip, default_options[:lobbyist_id, :client_id]).map { |struct|
      [struct.sum] }
  end

end
