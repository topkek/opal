require 'opal/parser/parser'
require 'opal/compiler'
require 'opal/dependency_builder'
require 'opal/context'
require 'opal/version'

module Opal
  # Root opal directory (root of gem)
  OPAL_DIR = File.expand_path('../..', __FILE__)

  # Full path to our opal.js runtime file
  OPAL_JS_PATH = File.join OPAL_DIR, 'runtime', 'opal.js'

  # Debug version
  OPAL_DEBUG_PATH = File.join OPAL_DIR, 'runtime', 'opal.debug.js'

  def self.build_runtime debug = false
    parser  = Opal::Parser.new :debug => debug
    runtime = File.join OPAL_DIR, 'runtime'
    order   = File.read(File.join runtime, 'corelib', 'load_order').strip.split
    core    = order.map { |c| File.read File.join(runtime, 'corelib', "#{c}.rb") }
    jsorder = File.read(File.join runtime, 'kernel', 'load_order').strip.split
    jscode  = jsorder.map { |j| File.read File.join(runtime, 'kernel', "#{j}.js") }

    parsed  = parser.parse core.join("\n"), '(corelib)'
    methods = Opal::Parser::METHOD_NAMES.map { |from, to| "'#{from}': 'm$#{to}$'" }
    result  = []

    result << Opal::HEADER
    result << "(function(undefined) {"
    result << jscode.join
    result << "var method_names = {#{methods.join ', '}};"
    result << "var reverse_method_names = {}; for (var id in method_names) {"
    result << "reverse_method_names[method_names[id]] = id;}"
    result << parsed
    result << "}).call(this);"

    result.join "\n"
  end

  def self.runtime_code
    return File.read OPAL_JS_PATH if File.exists? OPAL_JS_PATH
    build_runtime
  end

  def self.runtime_debug_code
    return File.read OPAL_DEBUG_PATH if File.exists? OPAL_DEBUG_PATH
    build_runtime true
  end

  HEADER = <<-HEADER
/*!
 * opal v#{Opal::VERSION}
 * http://opalscript.org
 *
 * Copyright 2011, Adam Beynon
 * Released under the MIT license
 */
HEADER
end
