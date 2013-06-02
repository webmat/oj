/* strict.c
 * Copyright (c) 2012, Peter Ohler
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 
 *  - Neither the name of Peter Ohler nor the names of its contributors may be
 *    used to endorse or promote products derived from this software without
 *    specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "oj.h"
#include "err.h"
#include "parse.h"

static void
add_value(ParseInfo pi, VALUE val) {
    pi->stack.head->val = val;
}

static void
add_cstr(ParseInfo pi, const char *str, size_t len) {
    VALUE	rstr = rb_str_new(str, len);

#if HAS_ENCODING_SUPPORT
    rb_enc_associate(rstr, oj_utf8_encoding);
#endif
    pi->stack.head->val = rstr;
}

static void
add_fix(ParseInfo pi, int64_t num) {
    pi->stack.head->val = LONG2NUM(num);
}

static VALUE
start_hash(ParseInfo pi) {
    return rb_hash_new();
}

static VALUE
hash_key(ParseInfo pi, const char *key, size_t klen) {
    VALUE	rkey = rb_str_new(key, klen);

#if HAS_ENCODING_SUPPORT
    rb_enc_associate(rkey, oj_utf8_encoding);
#endif
    if (Yes == pi->options.sym_key) {
	rkey = rb_str_intern(rkey);
    }
    return rkey;
}

static void
hash_set_cstr(ParseInfo pi, const char *key, size_t klen, const char *str, size_t len) {
    VALUE	rstr = rb_str_new(str, len);

#if HAS_ENCODING_SUPPORT
    rb_enc_associate(rstr, oj_utf8_encoding);
#endif
    rb_hash_aset(stack_peek(&pi->stack)->val, hash_key(pi, key, klen), rstr);
}

static void
hash_set_fix(ParseInfo pi, const char *key, size_t klen, int64_t num) {
    rb_hash_aset(stack_peek(&pi->stack)->val, hash_key(pi, key, klen), LONG2NUM(num));
}

static void
hash_set_value(ParseInfo pi, const char *key, size_t klen, VALUE value) {
    rb_hash_aset(stack_peek(&pi->stack)->val, hash_key(pi, key, klen), value);
}

static VALUE
start_array(ParseInfo pi) {
    return rb_ary_new();
}

static void
array_append_cstr(ParseInfo pi, const char *str, size_t len) {
    VALUE	rstr = rb_str_new(str, len);

#if HAS_ENCODING_SUPPORT
    rb_enc_associate(rstr, oj_utf8_encoding);
#endif
    rb_ary_push(stack_peek(&pi->stack)->val, rstr);
}

static void
array_append_fix(ParseInfo pi, int64_t num) {
    rb_ary_push(stack_peek(&pi->stack)->val, LONG2NUM(num));
}

static void
array_append_value(ParseInfo pi, VALUE value) {
    rb_ary_push(stack_peek(&pi->stack)->val, value);
}

void
oj_set_strict_callbacks(ParseInfo pi) {
    pi->start_hash = start_hash;
    pi->end_hash = 0;
    pi->hash_set_cstr = hash_set_cstr;
    pi->hash_set_fix = hash_set_fix;
    pi->hash_set_value = hash_set_value;
    pi->start_array = start_array;
    pi->end_array = 0;
    pi->array_append_cstr = array_append_cstr;
    pi->array_append_fix = array_append_fix;
    pi->array_append_value = array_append_value;
    pi->add_cstr = add_cstr;
    pi->add_fix = add_fix;
    pi->add_value = add_value;
}

VALUE
oj_strict_parse(int argc, VALUE *argv, VALUE self) {
    struct _ParseInfo	pi;

    oj_set_strict_callbacks(&pi);

    return oj_pi_parse(argc, argv, &pi);
}
