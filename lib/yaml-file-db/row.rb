module YDB
  class Row
    INTERNAL_VARS = [:@id, :@source].freeze

    attr_reader :id, :source

    def initialize(source, schema_path)
      @id = File.basename(source, ".yml")
      @source = source

      validate_filename()
      build(source, schema_path)
    end

    def build_relationships(db, keywords)
      iterate_over_columns do |key, value|
        if keywords.include?(key)
          if key.pluralize == key
            rows = []
            table = db.public_send(key.to_sym)
            value.each do |primary_key|
              row = table[primary_key]
              raise ValidationError.new("Invalid primary_key: #{primary_key} isn't part of table #{key}") if row.nil?
              rows << row
            end
            instance_variable_set("@#{key}", rows)
          else
            row = db.public_send(key.pluralize.to_sym)[value]
            raise ValidationError.new("Invalid primary_key: #{primary_key} isn't part of table #{key}") if row.nil?
            instance_variable_set("@#{key}", row)
          end
        end
      end
    end

    def check_relationships(db, keywords)
      iterate_over_columns do |key, value|
        if keywords.include?(key)
          # move row into array to make it iterable
          value = [value] if value.is_a?(YDB::Row)
          value.each do |row|
            if row.respond_to?(self.class.to_s.downcase.to_sym)
              unless row.public_send(self.class.to_s.downcase.to_sym) == self
                raise ValidationError.new("Inconsistent relationship: #{row.id} doesn't link back to #{self.id}")
              end
            elsif row.respond_to?(self.class.to_s.downcase.pluralize.to_sym)
              unless row.public_send(self.class.to_s.downcase.pluralize.to_sym).include?(self)
                raise ValidationError.new("Inconsistent relationship: #{row.id} doesn't link back to #{self.id}")
              end
            end
          end
        end
      end
    end

    private

    def build(source, schema_path)
      doc = YAML.load(File.read(source))
      raise ValidationError.new("Invalid YAML document") if doc == false

      schema = YAML.load(File.read(schema_path))
      begin
        JSON::Validator.validate!(schema, doc, :parse_data => false)
      rescue JSON::Schema::ValidationError => error
        raise ValidationError.new("Invalid data: #{error.message}")
      end

      doc.each do |name, value|
        instance_variable_set("@#{name}", value)
        next if self.respond_to?(name.to_sym)
        self.class.send("attr_reader", name.to_sym)
      end
    end

    def iterate_over_columns(&block)
      self.instance_variables.each do |var|
        next if INTERNAL_VARS.include?(var)
        key = var.to_s[1..-1]
        value = instance_variable_get(var)
        block.call(key, value)
      end
    end

    def validate_filename()
      raise ValidationError.new("Invalid filename: #{self.id} doesn't follow dash-case convention") unless self.id =~ /^[\w-]+$/
    end

  end
end
