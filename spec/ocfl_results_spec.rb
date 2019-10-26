require 'ocfl-tools'


describe OcflTools::OcflResults do

  describe ".new" do
    # shameless green
    it "returns a results object" do
      results = OcflTools::OcflResults.new
#      puts results.results
#      results.ok('O001', 'ContextA', 'a description')
#      results.ok('O001', 'ContextA', 'a different description')
#      results.ok('O001', 'ContextB', 'different context, different desc')
#      results.info('I001', 'check_digests', "I'm checking sha256 stuff")

#      results.warn('W099', 'check_digests', "This doesn't look right")

#      results.error('E066', 'check_digests', "I took an arrow to the knee!")

#      puts results.results

      results.error('E066', 'check_digests', "I took an arrow to the knee!")
      results.error('E066', 'check_digests', "I took another arrow to the knee!")
      results.error('E066', 'check_digests', "I took a 3rd! arrow to the knee!")
      results.error('E066', 'check_digests', "I quit. I'm off to join the city watch.")

      results.error('E066', 'check_hamsters', "Yup, hamsters")
      results.error('E066', 'check_hamsters', "Hamsters everywhere.")
      results.error('E066', 'check_hamsters', "This is my life now.")
    puts results.get_errors
    puts results.error_count

    end
  end

end
