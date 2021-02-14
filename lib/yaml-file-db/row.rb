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
      self.instance_variables.each do |var|
        next if INTERNAL_VARS.include? var
        keyword = var.to_s[1..-1]

        if keywords.include? keyword
          if keyword.pluralize == keyword
            array = instance_variable_get var
            entities = db.public_send(keyword.to_sym)
            value = []
            array.each do |primary_key|
              entity = entities[primary_key]
              raise ValidationError.new("invalid primary_key #{primary_key}") if entity.nil?
              value << entity
            end
            instance_variable_set("@#{keyword}", value)
          else
            primary_key = instance_variable_get var
            entity = db.public_send(keyword.pluralize.to_sym)[primary_key]
            raise ValidationError.new("invalid primary_key #{primary_key}") if entity.nil?
            instance_variable_set("@#{keyword}", entity)
          end
        end
      end
    end

    private

    def build(source, schema_path)
      doc = YAML.load(File.read(source))
      raise ValidationError.new("invalid YAML") if doc == false

      schema = YAML.load(File.read(schema_path))
      begin
        JSON::Validator.validate!(schema, doc, :parse_data => false)
      rescue JSON::Schema::ValidationError => error
        raise ValidationError.new("invalid data (#{error.message})")
      end

      doc.each do |name, value|
        instance_variable_set("@#{name}", value)
        next if self.respond_to? name.to_sym
        self.class.send("attr_reader", name.to_sym)
      end
    end

    def validate_filename()
      raise ValidationError.new("invalid filename") unless self.id =~ /^[\w-]+$/
    end

  end
end
