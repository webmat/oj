#!/usr/bin/env ruby
# encoding: UTF-8

# Ubuntu does not accept arguments to ruby when called using env. To get warnings to show up the -w options is
# required. That can be set in the RUBYOPT environment variable.
# export RUBYOPT=-w

$VERBOSE = true

$: << File.join(File.dirname(__FILE__), "../lib")
$: << File.join(File.dirname(__FILE__), "../ext")

require 'test/unit'
require 'stringio'
require 'date'
require 'bigdecimal'
require 'oj'

class OjWriter < ::Test::Unit::TestCase

  def test_string_writer_empty_array
    w = Oj::StringWriter.new(:indent => 0)
    w.push_array()
    w.pop()
    assert_equal('[]', w.to_s)
  end

  def test_string_writer_nested_array
    w = Oj::StringWriter.new(:indent => 0)
    w.push_array()
    w.push_array()
    w.pop()
    w.push_array()
    w.push_array()
    w.pop()
    w.pop()
    w.push_array()
    w.pop()
    w.pop()
    assert_equal('[[],[[]],[]]', w.to_s)
  end

  def test_string_writer_empty_object
    w = Oj::StringWriter.new(:indent => 0)
    w.push_object()
    w.pop()
    assert_equal('{}', w.to_s)
  end

  def test_string_writer_nested_object
    w = Oj::StringWriter.new(:indent => 0)
    w.push_object()
    w.push_object("a1")
    w.pop()
    w.push_object("a2")
    w.push_object("b")
    w.pop()
    w.pop()
    w.push_object("a3")
    w.pop()
    w.pop()
    assert_equal('{"a1":{},"a2":{"b":{}},"a3":{}}', w.to_s)
  end

  def test_string_writer_value_array
    w = Oj::StringWriter.new(:indent => 2)
    w.push_array()
    w.push_value(7)
    w.push_value(7.3)
    w.push_value(true)
    w.push_value(nil)
    w.push_value("a string")
    w.push_value({'a' => 65})
    w.push_value([1,2])
    w.pop()
    assert_equal(%|[
  7,
  7.3,
  true,
  null,
  "a string",
  {
    "a":65
  },
  [
    1,
    2
  ]
]
|, w.to_s)
  end

  def test_string_writer_block
    w = Oj::StringWriter.new(:indent => 0)
    w.push_object() {
      w.push_object("a1") {
        w.push_value(7, 'a7')
      }
      w.push_array("a2") {
        w.push_value('x')
        w.push_value(3)
      }
    }
    assert_equal('{"a1":{"a7":7},"a2":["x",3]}', w.to_s)
  end

  def test_string_writer_json
    w = Oj::StringWriter.new(:indent => 0)
    w.push_array()
    w.push_json('7')
    w.push_json('true')
    w.push_json(%|"a string"|)
    w.push_object()
    w.push_json('{"a":65}', 'x')
    w.pop()
    w.pop()
    assert_equal('[7,true,"a string",{"x":{"a":65}}]', w.to_s)
  end

  def test_string_writer_pop_excess
    w = Oj::StringWriter.new(:indent => 0)
    begin
      w.pop()
    rescue Exception
      assert(true)
      return
    end
    assert(false, "*** expected an exception")
  end

  def test_string_writer_obj_no_key
    w = Oj::StringWriter.new(:indent => 0)
    w.push_object()
    begin
      w.push_value(59)
    rescue Exception
      assert(true)
      return
    end
    assert(false, "*** expected an exception")
  end

  def test_string_writer_deep
    cnt = 1000
    w = Oj::StringWriter.new(:indent => 0)
    cnt.times do
      w.push_array()
    end
    cnt.times do
      w.pop()
    end
    # if no exception then passed
    assert(true)
  end

  def test_string_writer_pop_all
    w = Oj::StringWriter.new(:indent => 0)
    w.push_object()
    w.push_object("a1")
    w.pop()
    w.push_array("a2")
    w.push_value(3)
    w.push_array()
    w.pop_all()
    assert_equal('{"a1":{},"a2":[3,[]]}', w.to_s)
  end

  def test_string_writer_reset
    w = Oj::StringWriter.new(:indent => 0)
    w.push_array()
    w.pop()
    w.reset()
    assert_equal('', w.to_s)
  end

  # Stream Writer

  def test_stream_writer_empty_array
    output = StringIO.open("", "w+")
    w = Oj::StreamWriter.new(output, :indent => 0)
    w.push_array()
    w.pop()
    assert_equal('[]', output.string())
  end

  def test_stream_writer_mixed_stringio
    output = StringIO.open("", "w+")
    w = Oj::StreamWriter.new(output, :indent => 0)
    w.push_object()
    w.push_object("a1")
    w.pop()
    w.push_object("a2")
    w.push_array("b")
    w.push_value(7)
    w.push_value(true)
    w.push_value("string")
    w.pop()
    w.pop()
    w.push_object("a3")
    w.pop()
    w.pop()
    assert_equal('{"a1":{},"a2":{"b":[7,true,"string"]},"a3":{}}', output.string())
  end

  def test_stream_writer_mixed_file
    filename = 'open_file_writer_test.json'
    File.open(filename, "w") do |f|
      w = Oj::StreamWriter.new(f, :indent => 0)
      w.push_object()
      w.push_object("a1")
      w.pop()
      w.push_object("a2")
      w.push_array("b")
      w.push_value(7)
      w.push_value(true)
      w.push_value("string")
      w.pop()
      w.pop()
      w.push_object("a3")
      w.pop()
      w.pop()
    end
    content = File.read(filename)
    assert_equal('{"a1":{},"a2":{"b":[7,true,"string"]},"a3":{}}', content)
  end

end # OjWriter
