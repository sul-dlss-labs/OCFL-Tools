# frozen_string_literal: true

require 'ocfl-tools'

describe OcflTools::OcflResults do
  # puts results.get_context('check_hamsters')
  # puts "results.get_contexts"
  # puts JSON.pretty_generate(results.get_contexts)
  # puts "Now all results:"
  # puts JSON.pretty_generate(results.results)
  # puts results.get_contexts

  describe 'create some simple events' do
    results = OcflTools::OcflResults.new

    results.error('E111', 'test_error', 'I took an arrow to the knee!')
    results.warn('W111', 'test_warn', 'I took an arrow to the knee!')
    results.ok('O111', 'test_ok', 'I took an arrow to the knee!')
    results.info('I111', 'test_info', 'I took an arrow to the knee!')

    it 'expects one of each' do
      expect(results.error_count).to eql(1)
      expect(results.warn_count).to eql(1)
      expect(results.ok_count).to eql(1)
      expect(results.info_count).to eql(1)
    end
  end

  describe 'more simple checks' do
    results = OcflTools::OcflResults.new

    results.error('E111', 'test_error', 'I took an arrow to the knee!')
    results.error('E111', 'test_error', 'I took another arrow to the knee!')

    results.warn('W111', 'test_warn', 'I took an arrow to the knee!')
    results.warn('W111', 'test_warn', 'I took an arrow to the knee!')

    results.ok('O111', 'test_ok', 'I took an arrow to the knee!')
    results.ok('O111', 'test_ok', 'I took an arrow to the knee!')

    results.info('I111', 'test_info', 'I took an arrow to the knee!')
    results.info('I111', 'test_info', 'I took an arrow to the knee!')

    it 'dedupes same events with identical context and description' do
      expect(results.warn_count).to eql(1)
      expect(results.ok_count).to eql(1)
      expect(results.info_count).to eql(1)
    end

    it 'expects 2 errors and 2 descriptions' do
      #      puts results.get_errors
      expect(results.error_count).to eql(2)
      expect(results.get_errors).to match(
        'E111' => { 'test_error' => ['I took an arrow to the knee!', 'I took another arrow to the knee!'] }
      )
    end
  end

  describe 'checks contexts' do
    results = OcflTools::OcflResults.new

    results.error('E111', 'context_1', 'I took an arrow to the knee!')
    results.error('E111', 'context_1', 'I took another arrow to the knee!')

    results.error('E111', 'context_2', 'I took an arrow to the knee!')
    results.error('E111', 'context_2', 'I took another arrow to the knee!')
    results.error('E111', 'context_2', 'Plz stop knee hurts.')

    results.warn('W222', 'context_2', 'Someone is shooting arrows at me.')
    results.warn('W222', 'context_2', 'Everyone plays stealth archers.')

    it 'expects contexts to match these values' do
      expect(results.get_contexts).to match(
        'context_1' => { 'error' => { 'E111' => ['I took an arrow to the knee!', 'I took another arrow to the knee!'] } }, 'context_2' => { 'error' => { 'E111' => ['I took an arrow to the knee!', 'I took another arrow to the knee!', 'Plz stop knee hurts.'] }, 'warn' => { 'W222' => ['Someone is shooting arrows at me.', 'Everyone plays stealth archers.'] } }
      )
    end

    it 'expects 5 errors and 2 warns' do
      expect(results.error_count).to eql(5)
      expect(results.warn_count).to eql(2)
    end

    it 'gets context_2' do
      expect(results.get_context('context_2')).to match(
        'error' => { 'E111' => ['I took an arrow to the knee!', 'I took another arrow to the knee!', 'Plz stop knee hurts.'] }, 'warn' => { 'W222' => ['Someone is shooting arrows at me.', 'Everyone plays stealth archers.'] }
      )
    end
  end
end
