# frozen_string_literal: true

require "net/imap"
require "test/unit"

class SearchDataTests < Net::IMAP::TestCase
  SearchResult = Net::IMAP::SearchResult

  test "#modseq" do
    assert_nil SearchResult[12, 34].modseq
    assert_equal 123_456_789, SearchResult[12, 34, modseq: 123_456_789].modseq
  end

  test "#== ignores the order of elements" do
    unsorted = SearchResult[4, 2, 2048, 99]
    sorted   = SearchResult[2, 4, 99, 2048]
    array    = [2, 4, 99, 2048]
    assert_equal sorted, array
    assert_equal unsorted, array
  end

  test "#eql? doesn't ignore the order of elements" do
    unsorted = SearchResult[4, 2, 2048, 99]
    sorted   = SearchResult[2, 4, 99, 2048]
    refute_operator sorted,   :eql?, unsorted
    refute_operator unsorted, :eql?, sorted
    refute_equal sorted.hash, unsorted.hash
  end

  test "#== checks modseq" do
    unsorted = SearchResult[4, 2, 2048, 99, modseq: 99_999]
    sorted   = SearchResult[2, 4, 99, 2048, modseq: 99_999]
    assert_equal unsorted, sorted
    assert_equal sorted, unsorted

    nomodseq = SearchResult[2, 4, 99, 2048]
    refute_equal sorted, nomodseq
    refute_equal nomodseq, sorted
  end

  test "#eql? and #hash include the result type and modseq" do
    no_modseq    = SearchResult[1, 2]
    with_modseq  = SearchResult[1, 2, modseq: 3]
    other_modseq = SearchResult[1, 2, modseq: 4]
    assert_operator    no_modseq, :eql?,    no_modseq.dup
    assert_operator  with_modseq, :eql?,  with_modseq.dup
    assert_operator other_modseq, :eql?, other_modseq.dup
    assert_equal    no_modseq.hash,    no_modseq.dup.hash
    assert_equal  with_modseq.hash,  with_modseq.dup.hash
    assert_equal other_modseq.hash, other_modseq.dup.hash

    refute_operator    no_modseq, :eql?,  with_modseq
    refute_operator  with_modseq, :eql?,    no_modseq
    refute_operator  with_modseq, :eql?, other_modseq
    refute_operator other_modseq, :eql?,    no_modseq
    refute_operator other_modseq, :eql?,  with_modseq
    refute_equal    no_modseq.hash,  with_modseq.hash
    refute_equal  with_modseq.hash, other_modseq.hash
    refute_equal other_modseq.hash,    no_modseq.hash
  end

  test "SearchResult.new(nz_numbers) == / eql? SearchResult[*nz_numbers]" do
    array = [1, 5, 20, 3, 98]
    new_with_array_arg   = SearchResult.new(array)
    splatted_in_brackets = SearchResult[*array]
    [nil, 12345].each do |modseq|
      splatted_in_brackets = SearchResult[*array, modseq:]
      new_with_array_arg   = SearchResult.new(array, modseq:)
      assert_equal    splatted_in_brackets,        new_with_array_arg
      assert_equal    new_with_array_arg,        splatted_in_brackets
      assert_operator splatted_in_brackets, :eql?, new_with_array_arg
      assert_operator new_with_array_arg, :eql?, splatted_in_brackets
      assert_equal    splatted_in_brackets.hash,   new_with_array_arg.hash
      assert_equal    new_with_array_arg.hash,   splatted_in_brackets.hash
    end
  end

  test "SearchResult[*nz_numbers] == Array[*nz_numbers]" do
    array  = [1, 5, 20, 3, 98]
    result = SearchResult[*array]
    assert_equal array, result
    assert_equal result, array
  end

  test "SearchResult[*nz_numbers] not eql? Array[*nz_numbers]" do
    array  = [1, 5, 20, 3, 98]
    result = SearchResult[*array]
    pend "See comments on #738" do
      refute_operator result, :eql?, array
    end
    pend "See comments on #738" do
      refute_operator result.hash, :eql?, array.hash
    end
  end

  # NOTE: this subclass is NOT overriding #==, #hash, or #eql?
  Subclass = Class.new(SearchResult)

  test "SearchResult[...] == / eql? Subclass[...]" do
    array    = [1, 5, 20, 3, 98]
    result   = SearchResult[*array]
    subclass = Subclass[*array]
    assert_operator result, :eql?, subclass
    assert_equal result.hash, subclass.hash
    modseq   = 12345
    result   = SearchResult[*array, modseq:]
    subclass = Subclass[*array, modseq:]
    pend "See comments on #738" do
      assert_operator result, :eql?, subclass
    end
    pend "See comments on #738" do
      assert_equal result.hash, subclass.hash
    end
  end

  test "SearchResult[*nz_numbers, modseq: nz_number] != / not eql? Array[*nz_numbers]" do
    array  = [1, 5, 20, 3, 98]
    result = SearchResult[*array, modseq: 123456]
    refute_equal result, array
    refute_operator result, :eql?, array
    refute_equal result.hash, array.hash
  end

  test "Array[*nz_numbers] == / eql? SearchResult[*nz_numbers, modseq: nz_number]" do
    array  = [1, 5, 20, 3, 98]
    result = SearchResult[*array, modseq: 123456]
    assert_equal array, result
    assert_operator array, :eql?, result
  end

  test "SearchResult[*nz_numbers] == Array[*differently_sorted]" do
    array  = [1, 5, 20, 3, 98]
    result = SearchResult[*array.reverse]
    assert_equal result, array
  end

  test "SearchResult[*nz_numbers] not eql? Array[*differently_sorted]" do
    array  = [1, 5, 20, 3, 98]
    result = SearchResult[*array.reverse]
    refute_operator result, :eql?, array
    refute_equal result.hash, array.hash
  end

  test "Array[*nz_numbers] != / not eql? SearchResult[*differently_sorted]" do
    array  = [1, 5, 20, 3, 98]
    result = SearchResult[*array.reverse]
    refute_equal array, result
    refute_operator result, :eql?, array
    refute_equal array.hash, result.hash
  end

  test "#inspect" do
    assert_equal "[1, 2, 3]", Net::IMAP::SearchResult[1, 2, 3].inspect
    assert_equal("Net::IMAP::SearchResult[1, 3, modseq: 9]",
                 Net::IMAP::SearchResult[1, 3, modseq: 9].inspect)
  end

  test "#to_s" do
    assert_equal "* SEARCH 1 2 3", Net::IMAP::SearchResult[1, 2, 3].to_s
    assert_equal("* SEARCH 3 2 1 (MODSEQ 9)",
                 Net::IMAP::SearchResult[3, 2, 1, modseq: 9].to_s)
  end

  test "#to_s(type)" do
    assert_equal "* SEARCH 1 3", Net::IMAP::SearchResult[1, 3].to_s("SEARCH")
    assert_equal "* SORT 1 2 3", Net::IMAP::SearchResult[1, 2, 3].to_s("SORT")
    assert_equal("* SORT 99 111 44 (MODSEQ 999)",
                 Net::IMAP::SearchResult[99, 111, 44, modseq: 999].to_s("SORT"))
    assert_equal("99 111 44 (MODSEQ 999)",
                 Net::IMAP::SearchResult[99, 111, 44, modseq: 999].to_s(nil))
  end

  test "#to_sequence_set" do
    assert_equal("1,3", Net::IMAP::SearchResult[1, 3].to_sequence_set.to_s)
    assert Net::IMAP::SearchResult[1, 3].to_sequence_set.frozen?
    assert_equal("1:3", Net::IMAP::SearchResult[1, 2, 3].to_sequence_set.to_s)
    assert_equal(
      "44,99,111",
      Net::IMAP::SearchResult[99, 111, 44, modseq: 999].to_sequence_set.to_s
    )
    assert_equal(
      "1:4,9:10,12",
      Net::IMAP::SearchResult[9, 1, 2, 3, 4, 10, 12].to_sequence_set.to_s
    )
    assert_equal(Net::IMAP::SequenceSet.empty,
                 Net::IMAP::SearchResult[].to_sequence_set)
    assert Net::IMAP::SearchResult[].to_sequence_set.frozen?
  end
end
