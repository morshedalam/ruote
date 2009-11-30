#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


module Ruote

  # Not really a parser, more an AST builder.
  #
  def self.define (*attributes, &block)

    RubyDsl.create_branch('define', attributes, &block)
  end

  def self.process_definition (*attributes, &block)

    define(*attributes, &block)
  end

  # :nodoc:
  #
  module RubyDsl

    class BranchContext

      def initialize (name, attributes)

        @name = name
        @attributes = attributes
        @children = []
      end

      def method_missing (m, *args, &block)

        @children.push(
          Ruote::RubyDsl.create_branch(m.to_s, args, &block))
      end

      def to_a

        [ @name, @attributes, @children ]
      end
    end

    def self.create_branch (name, attributes, &block)

      while name[0, 1] == '_'
        name = name[1..-1]
      end

      h = attributes.inject({}) { |h1, a|
        a.is_a?(Hash) ? h1.merge!(a) : h1[a] = nil
        h1
      }.inject({}) { |h1, (k, v)|
        h1[k.to_s] = v.is_a?(Symbol) ? v.to_s : v
        h1
      }

      c = BranchContext.new(name, h)
      c.instance_eval(&block) if block
      c.to_a
    end
  end
end

