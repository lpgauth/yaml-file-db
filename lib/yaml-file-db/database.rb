module YDB
  class Database

    INTERNAL_VARS = [:@errors, :@schemas, :@source].freeze

    attr_reader :errors, :schemas, :source

    def initialize(source, schemas)
      @errors = []
      @schemas = schemas
      @source = source
    end

    def build()
      build_tables()
      build_relationships()
      check_relationships()
      self
    end

    private

    def build_tables()
      Dir["#{@source}/*"].each do |table_path|
        table = {}

        table_name = File.basename(table_path)
        klass_name = table_name.singularize.capitalize
        Object.const_set(klass_name, Class.new(Row))
        schema_path = "#{@schemas}/#{table_name.singularize}.yml"

        Dir["#{table_path}/*.yml"].each do |source|
          begin
            row = Object.const_get(klass_name).new(source, schema_path)
            table[row.id] = row
          rescue ValidationError => error
            @errors << "[#{source.split("/")[-3..-1].join("/")}] #{error.to_s}"
          end
        end

        instance_variable_set("@#{table_name}", table)
        self.class.send("attr_reader", table_name.to_sym)
      end
    end

    def build_relationships()
      keywords = keywords()
      iterate_over_rows do |row|
        row.build_relationships(self, keywords)
      end
    end

    def check_relationships()
      keywords = keywords()
      iterate_over_rows do |row|
        row.check_relationships(self, keywords)
      end
    end

    private

    def keywords()
      keywords = []
      (self.instance_variables - INTERNAL_VARS).each do |var|
        keywords << var.to_s[1..-1]
        keywords << var.to_s[1..-1].singularize
      end
      keywords
    end

    def iterate_over_rows(&block)
      self.instance_variables.each do |var|
        next if INTERNAL_VARS.include? var
        table = instance_variable_get var
        table.each do |id, row|
          begin
            block.call(row)
          rescue ValidationError => error
            @errors << "[#{row.source.split("/")[-3..-1].join("/")}] #{error.to_s}"
          end
        end
      end
    end

  end
end
