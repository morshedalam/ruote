#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
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

require 'thread'
require 'ruote/engine/context'


module Ruote

  class WorkQueue
    include EngineContext

    protected

    def process (unit)
      begin
        target, method, args = unit
        target.send(method, *args)
      rescue Exception => e
        p e
      end
    end
  end

  # A lazy, no-thread work queue.
  #
  # Each time a piece of work is queue, #step is called.
  #
  # Breaks with a simple sequence with 600 steps. Not stack safe !
  #
  class PlainWorkQueue < WorkQueue

    def initialize

      @queue = Queue.new
    end

    def push (target, method, *args)

      @queue.push([target, method, args])
      step
    end

    def step

      return if @queue.size < 1
      process(@queue.pop)
    end
  end

  class ThreadWorkQueue < WorkQueue

    def initialize

      @queue = Queue.new

      @thread = Thread.new do
        loop do
          process(@queue.pop)
        end
      end
    end

    def push (target, method, *args)

      @queue.push([target, method, args])
    end
  end

  class FiberWorkQueue < WorkQueue

    def initialize

      @queue = Queue.new
      @unit = nil

      @fiber = Fiber.new do
        loop do
          process(@unit)
          Fiber.yield
        end
      end

      @thread = Thread.new do
        loop do
          target, method, args = @queue.pop
          target.send(method, *args)
          @unit = @queue.pop
          @fiber.resume
        end
      end
    end

    def push (target, method, *args)

      @queue.push([target, method, args])
    end
  end

end

