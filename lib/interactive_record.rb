require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name 
    name = self.to_s.downcase.pluralize
  end 
  
  def self.column_names
    columns = DB[:conn].execute("PRAGMA table_info(#{table_name})")
    names = columns.map do |column| 
      column["name"]
    end 
    names.compact
  end 

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end
  
  def table_name_for_insert
    self.class.table_name
  end
  
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end
  
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end
  
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
  
  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end
  
  def self.find_by(hash)
    sql = "SELECT * FROM #{self.table_name} WHERE #{hash.keys[0]} = #{hash[hash.keys[0]]}"
    DB[:conn].execute(sql)
  end
end