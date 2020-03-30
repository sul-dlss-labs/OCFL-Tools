# frozen_string_literal: true

require 'ocfl-tools'


test_root = File.join(File.dirname(__dir__), 'spec', 'fixtures', '1.0', 'error-objects')
fixture_dirs  = []

Dir.chdir("#{test_root}")
Dir.glob('*').select do |file|
  fixture_dirs << file if File.directory? file
end

fixture_dirs.each do | fixture_dir |

  describe OcflTools::OcflValidator do
    describe 'Error code testing' do

      # The expected error code is the first element of the directory name.
      expected_error = fixture_dir.split('_')[0]
      #puts "My expected error is #{expected_error}"

      ocfl_dir = File.join(File.dirname(__dir__), 'spec', 'fixtures', '1.0', 'error-objects', "#{fixture_dir}" )
      validate_me = OcflTools::OcflValidator.new(ocfl_dir)
      validate_me.validate_ocfl_object_root
      puts "Validating error code #{expected_error}"
      #puts validate_me.results.get_errors
      #validate_me.results.print

      case
        # Example for how to  handle objects with multiple (expected) errors.
      when expected_error == 'E215'
        validate_me.results.print
        it "expects error code E215" do
          # E102 is the generic 'required file missing from object root'
          # E215 is the explicit missing Inventory file.
          expect(validate_me.results.get_errors).to include('E102')
          expect(validate_me.results.get_errors).to include('E215')
        end

      when expected_error == 'E211'
        it "expects error code E211" do
          # We get some E210 as well.
          expect(validate_me.results.get_errors).to include('E211')
          expect(validate_me.results.get_errors).to include('E210')
        end

        when expected_error == 'E216'
          it "expects error code E216" do
            # We get some E210 as well.
            expect(validate_me.results.get_errors).to include('E216')
            expect(validate_me.results.get_errors).to include('E210')
          end

        when expected_error == 'E217'
          it "expects error code E217" do
            # We get some E210 as well.
            expect(validate_me.results.get_errors).to include('E217')
            expect(validate_me.results.get_errors).to include('E210')
          end

        else
          it "expects error code #{expected_error}" do
            expect(validate_me.results.get_errors).to include(expected_error)
            expect(validate_me.results.get_errors.count).to equal 1
          end
      end


    end
  end

end
