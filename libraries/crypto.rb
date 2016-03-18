#
# Cookbook Name:: splunk
# Libraries:: crypto
#
# Author: Marat Vyshegorodtsev <marat.vyshegorodtsev@gmail.com>
# Copyright (c) 2016, Bonakodo Limited <office@bonakodo.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'base64'

# This file provides helpers for password encryption used by Splunk
module Splunk
  # RC4 implementation taken from https://github.com/caiges/Ruby-RC4
  class RC4
    def initialize(str)
      raise SyntaxError, 'RC4: Key supplied is blank' if str.eql?('')
      initialize_state(str)
      @q1 = 0
      @q2 = 0
    end

    def encrypt!(text)
      index = 0
      while index < text.length
        @q1 = (@q1 + 1) % 256
        @q2 = (@q2 + @state[@q1]) % 256
        @state[@q1], @state[@q2] = @state[@q2], @state[@q1]
        text.setbyte(index, text.getbyte(index) ^ @state[
          (@state[@q1] + @state[@q2]) % 256])
        index += 1
      end
      text
    end

    alias :decrypt! :encrypt!

    def encrypt(text)
      encrypt!(text.dup)
    end

    alias :decrypt :encrypt

    private

    # The initial state which is then modified by the key-scheduling algorithm
    INITIAL_STATE = (0..255).to_a

    # Performs the key-scheduling algorithm to initialize the state.
    def initialize_state(key)
      i = j = 0
      @state = INITIAL_STATE.dup
      key_length = key.length
      while i < 256
        j = (j + @state[i] + key.getbyte(i % key_length)) % 256
        @state[i], @state[j] = @state[j], @state[i]
        i += 1
      end
    end
  end

  def splunk_encrypted_password(plaintext)
    pwd = plaintext.unpack('c*')
    secret_file = ::File.join(node['splunk']['user']['home'],
                              'etc/auth/splunk.secret')

    rc4key = ::IO.read(secret_file).strip![0..15]
    xorkey = 'DEFAULTSA'.unpack('c*')
    xorkey += xorkey while xorkey.size < pwd.size

    pwd = pwd.zip(xorkey).map { |c1, c2| c1 ^ c2 }.pack('c*') + "\0"
    pwd = Splunk::RC4.new(rc4key).encrypt(pwd)
    '$1$' + Base64.encode64(pwd).strip!
  end
end
