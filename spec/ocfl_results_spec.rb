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
      results.error('E066', 'check_hamsters', "This is my life now.")
      results.error('E066', 'check_hamsters', "This is my life now.")

      results.warn('W111', 'check_hamsters', "I think I see a hamster")
      puts "GET RESULTS"
      puts results.get_contexts
      results.warn('W111', 'check_hamsters', "I think I see another hamster")
      puts "GET RESULTS"
      puts results.get_contexts
      results.warn('W222', 'check_hamsters', "A different warning")
      puts "GET RESULTS"
      puts results.get_contexts
      results.warn('W222', 'check_hamsters', "Another different warning")
      puts "GET RESULTS"
      puts results.get_contexts
      results.warn('W111', 'check_hamsters', "whaaat")
      results.warn('W111', 'check_hamsters', "whaaat")

      results.info('I911', 'check_hamsters', "Thank you for subscribing to Hamster Facts")

      results.info('I911', 'check_location', "Welcome to Noneshall Pass")
      results.info('I911', 'check_location', "Gateway to Noneshall Valley!")

        results.ok('O001', 'check_hamsters', "All hamsters present and accounted for.")

      expect(results.get_errors).to match(
        {"E066"=>{"check_digests"=>["I took an arrow to the knee!", "I took another arrow to the knee!", "I took a 3rd! arrow to the knee!", "I quit. I'm off to join the city watch."], "check_hamsters"=>["Yup, hamsters", "Hamsters everywhere.", "This is my life now."]}}
      )
      expect(results.error_count).to equal 7

      # puts results.get_context('check_hamsters')
      puts "results.get_contexts"
      puts JSON.pretty_generate(results.get_contexts)
      puts "Now all results:"
      puts JSON.pretty_generate(results.results)
      #puts results.get_contexts

      # Check that we can combine data from different results objects.
      new_results = OcflTools::OcflResults.new
      new_results.warn('W111', 'check_hamsters', "This is strangely unpleasant")
      results.add_results(new_results).results
      puts JSON.pretty_generate(results.results)
    end
  end

end
