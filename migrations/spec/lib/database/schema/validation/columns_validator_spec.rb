# frozen_string_literal: true

RSpec.describe ::Migrations::Database::Schema::Validation::ColumnsValidator do
  subject(:validator) { described_class.new(config, errors, db) }

  let(:errors) { [] }
  let(:config) { { schema: schema_config } }
  let(:users_columns) { { include: %w[id username created_at updated_at] } }
  let(:schema_config) do
    { tables: { users: { columns: users_columns } }, global: { columns: { exclude: [] } } }
  end
  let(:db) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
  let(:columns) do
    [
      instance_double(
        ActiveRecord::ConnectionAdapters::PostgreSQL::Column,
        name: "id",
        type: :integer,
      ),
      instance_double(
        ActiveRecord::ConnectionAdapters::PostgreSQL::Column,
        name: "username",
        type: :string,
      ),
      instance_double(
        ActiveRecord::ConnectionAdapters::PostgreSQL::Column,
        name: "created_at",
        type: :datetime,
      ),
      instance_double(
        ActiveRecord::ConnectionAdapters::PostgreSQL::Column,
        name: "updated_at",
        type: :datetime,
      ),
    ]
  end

  before { allow(db).to receive(:columns).with("users").and_return(columns) }

  describe "#validate" do
    it "adds an error if added columns already exist" do
      users_columns[:add] = [{ name: "username" }, { name: "created_at" }]

      validator.validate("users")
      expect(errors).to contain_exactly(
        I18n.t(
          "schema.validator.tables.added_columns_exist",
          table_name: "users",
          column_names: "created_at, username",
        ),
      )
    end

    it "adds an error if included columns do not exist" do
      users_columns[:include] << "missing_column" << "another_missing"

      validator.validate("users")
      expect(errors).to contain_exactly(
        I18n.t(
          "schema.validator.tables.included_columns_missing",
          table_name: "users",
          column_names: "another_missing, missing_column",
        ),
      )
    end

    it "adds an error if excluded columns do not exist" do
      users_columns.replace({ exclude: %w[missing_column another_missing] })

      validator.validate("users")
      expect(errors).to contain_exactly(
        I18n.t(
          "schema.validator.tables.excluded_columns_missing",
          table_name: "users",
          column_names: "another_missing, missing_column",
        ),
      )
    end

    describe "modified columns validation" do
      it "adds an error if modified columns do not exist" do
        users_columns[:modify] = [
          { name: "missing_column", datatype: "text" },
          { name: "another_missing", datatype: "integer" },
        ]

        validator.validate("users")
        expect(errors).to contain_exactly(
          I18n.t(
            "schema.validator.tables.modified_columns_missing",
            table_name: "users",
            column_names: "another_missing, missing_column",
          ),
        )
      end

      it "adds an error if included columns are also modified" do
        users_columns[:modify] = [
          { name: "username", datatype: "text" },
          { name: "id", datatype: "bigint" },
        ]

        validator.validate("users")
        expect(errors).to contain_exactly(
          I18n.t(
            "schema.validator.tables.modified_columns_included",
            table_name: "users",
            column_names: "id, username",
          ),
        )
      end

      it "adds an error if excluded columns are also modified" do
        users_columns.delete(:include)
        users_columns[:exclude] = %w[username id]
        users_columns[:modify] = [
          { name: "username", datatype: "text" },
          { name: "id", datatype: "bigint" },
        ]

        validator.validate("users")
        expect(errors).to contain_exactly(
          I18n.t(
            "schema.validator.tables.modified_columns_excluded",
            table_name: "users",
            column_names: "id, username",
          ),
        )
      end
    end

    describe "column configuration validation" do
      context "when included columns are configured" do
        it "adds no error when all columns are included" do
          users_columns[:include] = %w[id username created_at updated_at]

          validator.validate("users")
          expect(errors).to eq([])
        end
      end
    end
  end
end
