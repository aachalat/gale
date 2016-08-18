/*

  Copyright 2016 Andrew Chalaturnyk


  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at


      http://www.apache.org/licenses/LICENSE-2.0


  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/



/*   **** List macros ****

NOTE: the first entry in the list must exist and is the sentinal value.

The sentinal value is both the top and the bottom of the list.

No branching is required on insertion or deletion and two lists can
be joined in constant time.

TODO: pipeline performance tests.  This approach may end up slower due
to memory depenancies causing pauses in the pipeline... and the
occational extra work required to make sure sentinal value is around.

*/

#pragma once

#include <stddef.h>

#define _LIST_ENTRY_TYPE_NAME(T) _## T ##_list_entry
#define _LE_FUNC_NAME(N,F)  N ##_## F
#define _LE_ST(T) struct T

#define LIST_ENTRY_TYPE(T) struct _LIST_ENTRY_TYPE_NAME(T)
#define LIST_ENTRY_MEMBERS(T) \
    LIST_ENTRY_TYPE(T) *next;\
    LIST_ENTRY_TYPE(T) **ap

#define _LE_CAST(PTR,T) (LIST_ENTRY_TYPE(T)*)(PTR)
#define _LE_CAST2(PTR,T) (LIST_ENTRY_TYPE(T)**)(PTR)
#define _LE_DREF_NEXT(PTR,T) (_LE_CAST(PTR,T))->next
#define _LE_DREF_AP(PTR,T) (_LE_CAST(PTR,T))->ap

#define LE_MC_IS_EMPTY(PTR,T) (_LE_DREF_NEXT(PTR,T)==_LE_CAST(PTR,T))
#define LE_MC_IS_DONE(PTR,LIST,T) (_LE_CAST(PTR,T)==_LE_CAST(LIST,T))
#define LE_MC_AFTER(PTR,T) (_LE_ST(T)**)&_LE_DREF_NEXT(PTR,T)
#define LE_MC_BEFORE(PTR,T) (_LE_ST(T)**)_LE_DREF_AP(PTR,T)
#define LE_MC_NEXT(PTR,T) (_LE_ST(T)*)_LE_DREF_NEXT(PTR,T)
#define LE_MC_TOP    LE_MC_AFTER
#define LE_MC_BOTTOM LE_MC_BEFORE
#define LE_MC_FIRST  LE_MC_NEXT

#define _LE_BOTTOM(N) _LE_FUNC_NAME(N,bottom)
#define _LE_BOTTOM_PROTO(IE,N,L,T) \
IE _LE_ST(T) **_LE_BOTTOM(N)(L *_e0)
#define _LE_BOTTOM_DEF(IE,N,L,T) \
_LE_BOTTOM_PROTO(IE,N,L,T)\
{\
    _LE_ST(T) **pv = LE_MC_BOTTOM(_e0,T);\
    return pv;\
}

#define _LE_TOP(N) _LE_FUNC_NAME(N,top)
#define _LE_TOP_PROTO(IE,N,L,T) \
IE _LE_ST(T) **_LE_TOP(N)(L *_e0)
#define _LE_TOP_DEF(IE,N,L,T) \
_LE_TOP_PROTO(IE,N,L,T)\
{return LE_MC_TOP(_e0,T);}

#define _LE_FIRST(N) _LE_FUNC_NAME(N,first)
#define _LE_FIRST_PROTO(IE,N,L,T) \
IE _LE_ST(T) *_LE_FIRST(N)(L *_e0)
#define _LE_FIRST_DEF(IE,N,L,T) \
_LE_FIRST_PROTO(IE,N,L,T)\
{return LE_MC_FIRST(_e0,T);}

#define _LE_NEXT(E) _LE_FUNC_NAME(E,next)
#define _LE_NEXT_PROTO(IE,E,T) \
IE _LE_ST(T) *_LE_NEXT(E)(_LE_ST(T) *_e0)
#define _LE_NEXT_DEF(IE,E,T) \
_LE_NEXT_PROTO(IE,E,T)\
{return LE_MC_NEXT(_e0,T);}

#define _LE_SET_NEXT(E) _LE_FUNC_NAME(E,set_next)
#define _LE_SET_NEXT_PROTO(IE,E,T) \
IE _LE_ST(T) *_LE_SET_NEXT(E)(_LE_ST(T) *_e0, _LE_ST(T) *_e1)
#define _LE_SET_NEXT_DEF(IE,E,T) \
_LE_SET_NEXT_PROTO(IE,E,T)\
{\
    _LE_DREF_NEXT(_e0,T) = _LE_CAST(_e1,T);\
    return _e0;\
}

#define _LE_AFTER(E) _LE_FUNC_NAME(E,after)
#define _LE_AFTER_PROTO(IE,E,T) \
IE _LE_ST(T) **_LE_AFTER(E)(_LE_ST(T) *_e0)
#define _LE_AFTER_DEF(IE,E,T) \
_LE_AFTER_PROTO(IE,E,T) \
{return LE_MC_AFTER(_e0,T);}

#define _LE_BEFORE(E) _LE_FUNC_NAME(E,before)
#define _LE_BEFORE_PROTO(IE,E,T) \
IE _LE_ST(T) **_LE_BEFORE(E)(_LE_ST(T) *_e0)
#define _LE_BEFORE_DEF(IE,E,T) \
_LE_BEFORE_PROTO(IE,E,T) \
{return LE_MC_BEFORE(_e0,T);}

#define _LE_PREV(N) _LE_FUNC_NAME(N,prev)
#define _LE_PREV_PROTO(IE,N,L,T) \
IE _LE_ST(T) *_LE_PREV(N)(_LE_ST(T) *_e0, L *_l0)
#define _LE_PREV_DEF(IE,N,L,T) \
_LE_PREV_PROTO(IE,N,L,T) \
{\
    LIST_ENTRY_TYPE(T) *prev = \
    _LE_CAST((((char*)(_LE_DREF_AP(_e0,T)))\
        -offsetof(LIST_ENTRY_TYPE(T), next)),T);\
    if (prev ==_LE_CAST(_l0,T)) prev = \
    _LE_CAST((((char*)(prev->ap))\
        -offsetof(LIST_ENTRY_TYPE(T), next)),T);\
    return (_LE_ST(T)*)prev;\
}

#define _LE_CONTAINS(N) _LE_FUNC_NAME(N,contains)
#define _LE_CONTAINS_PROTO(IE,N,L,T) \
IE int _LE_CONTAINS(N)(_LE_ST(T) *_e0, L *_l0)
#define _LE_CONTAINS_DEF(IE,N,L,T) \
_LE_CONTAINS_PROTO(IE,N,L,T) \
{\
    LIST_ENTRY_TYPE(T) *c = (_LE_CAST(_l0,T))->next;\
    while (!LE_MC_IS_DONE(c,_l0,T)) {\
        if (c == _LE_CAST(_e0,T)) return 1;\
        c = c->next;\
    }\
    return 0;\
}

#define _LE_IS_DONE(N) _LE_FUNC_NAME(N,is_done)
#define _LE_IS_DONE_PROTO(IE,N,L,T) \
IE int _LE_IS_DONE(N)(_LE_ST(T) *_e0, L *_l0)
#define _LE_IS_DONE_DEF(IE,N,L,T) \
_LE_IS_DONE_PROTO(IE,N,L,T) \
{\
    return _LE_CAST(_e0,T)==_LE_CAST(_l0,T);\
}

#define _LE_IS_EMPTY(N) _LE_FUNC_NAME(N,is_empty)
#define _LE_IS_EMPTY_PROTO(IE,N,L,T) \
IE int _LE_IS_EMPTY(N)(L *_a0)
#define _LE_IS_EMPTY_DEF(IE,N,L,T) \
_LE_IS_EMPTY_PROTO(IE,N,L,T) \
{return LE_MC_IS_EMPTY(_a0,T);}

#define _LE_ATTACH(E) _LE_FUNC_NAME(E,attach)
#define _LE_ATTACH_PROTO(IE,E,T) \
IE void _LE_ATTACH(E)(_LE_ST(T) *_e0, _LE_ST(T) **_a0)
#define _LE_ATTACH_DEF(IE,E,T) \
_LE_ATTACH_PROTO(IE,E,T)\
{\
    LIST_ENTRY_TYPE(T) *x = *_LE_CAST2(_a0,T);\
    *_LE_CAST2(_a0,T) = _LE_CAST(_e0,T);\
    _LE_DREF_AP(_e0,T) = _LE_CAST2(_a0,T);\
    _LE_DREF_NEXT(_e0,T) = x;\
    x->ap = &_LE_DREF_NEXT(_e0, T);\
}

#define _LE_DETACH(E) _LE_FUNC_NAME(E,detach)
#define _LE_DETACH_PROTO(IE,E,T) \
IE void _LE_DETACH(E)(_LE_ST(T) *_e0)
#define _LE_DETACH_DEF(IE,E,T) \
_LE_DETACH_PROTO(IE,E,T) \
{\
    LIST_ENTRY_TYPE(T)  *x  = _LE_DREF_NEXT(_e0, T);\
    LIST_ENTRY_TYPE(T) **ap = _LE_DREF_AP(_e0,T);\
    *(ap) = x;\
    x->ap = ap;\
}

#define _LE_RESET(N) _LE_FUNC_NAME(N,reset)
#define _LE_RESET_PROTO(IE,N,L,T) \
IE void _LE_RESET(N)(L *_l0)
#define _LE_RESET_DEF(IE,N,L,T) \
_LE_RESET_PROTO(IE,N,L,T) \
{\
    _LE_DREF_NEXT(_l0,T) = _LE_CAST(_l0,T);\
    _LE_DREF_AP(_l0,T) = &_LE_DREF_NEXT(_l0,T);\
}

/*

#define _LE_ENABLE_NULL(N) _LE_FUNC_NAME(N,enable_null)
#define _LE_ENABLE_NULL_PROTO(IE,N,L,T) \
IE void _LE_ENABLE_NULL(N)(L *_l0)
#define _LE_ENABLE_NULL_DEF(IE,N,L,T) \
_LE_ENABLE_NULL_PROTO(IE,N,L,T) \
{\
    *_LE_DREF_AP(_l0,T) = NULL;\
}


#define _LE_DISABLE_NULL(N) _LE_FUNC_NAME(N,disable_null)
#define _LE_DISABLE_NULL_PROTO(IE,N,L,T) \
IE void _LE_DISABLE_NULL(N)(L *_l0)
#define _LE_DISABLE_NULL_DEF(IE,N,L,T) \
_LE_DISABLE_NULL_PROTO(IE,N,L,T) \
{\
    *_LE_DREF_AP(_l0,T) = _LE_CAST(_l0,T);\
}
*/

#define _LE_LENGTH(N) _LE_FUNC_NAME(N,length)
#define _LE_LENGTH_PROTO(IE,N,E,L,T) \
IE size_t _LE_LENGTH(N)(L *_l0)
#define _LE_LENGTH_DEF(IE,N,E,L,T) \
_LE_LENGTH_PROTO(IE,N,E,L,T) \
{\
    size_t count=0;\
    _LE_ST(T) *_e0 = _LE_FIRST(N)(_l0);\
    while (!_LE_IS_DONE(N)(_e0,_l0)){\
        count++;\
        _e0 = _LE_NEXT(E)(_e0);\
    }\
    return count;\
}


#define _LE_PUSH(N) _LE_FUNC_NAME(N,push)
#define _LE_PUSH_PROTO(IE,N,E,L,T) \
IE void _LE_PUSH(N)(_LE_ST(T)* _e0, L *_l0)
#define _LE_PUSH_DEF(IE,N,E,L,T) \
_LE_PUSH_PROTO(IE,N,E,L,T) \
{\
    _LE_DREF_AP(_e0,T) = &_LE_DREF_NEXT(_l0,T);\
    _LE_DREF_NEXT(_e0,T) = _LE_DREF_NEXT(_l0,T);\
    _LE_DREF_NEXT(_l0,T)->ap = &_LE_DREF_NEXT(_e0,T);\
    _LE_DREF_NEXT(_l0,T) = _LE_CAST(_e0,T);\
}

#define _LE_POP(N) _LE_FUNC_NAME(N,pop)
#define _LE_POP_PROTO(IE,N,E,L,T) \
IE _LE_ST(T)* _LE_POP(N)(L *_l0)
#define _LE_POP_DEF(IE,N,E,L,T) \
_LE_POP_PROTO(IE,N,E,L,T) \
{\
    LIST_ENTRY_TYPE(T) *x = _LE_DREF_NEXT(_l0,T);\
    LIST_ENTRY_TYPE(T) *n = x->next;\
    _LE_DREF_NEXT(_l0,T) = n;\
    _LE_DREF_AP(n,T) = &_LE_DREF_NEXT(_l0,T);\
    return (_LE_ST(T)*) x;\
}

#define _LE_COMBINE_TOP(N) _LE_FUNC_NAME(N,combine_top)
#define _LE_COMBINE_TOP_PROTO(IE,N,L,T) \
IE void _LE_COMBINE_TOP(N)(L *_l0, L *_l1)
#define _LE_COMBINE_TOP_DEF(IE,N,L,T) \
_LE_COMBINE_TOP_PROTO(IE,N,L,T) \
{\
    if (_LE_IS_EMPTY(N)(_l1)) return;\
    *_LE_DREF_AP(_l1,T) = _LE_DREF_NEXT(_l0,T);\
    _LE_DREF_AP(_LE_DREF_NEXT(_l0,T),T) = _LE_DREF_AP(_l1,T);\
    _LE_DREF_AP(_LE_DREF_NEXT(_l1,T),T) = &_LE_DREF_NEXT(_l0,T);\
    _LE_DREF_NEXT(_l0,T) = _LE_DREF_NEXT(_l1,T);\
    _LE_RESET(N)(_l1);\
}

#define _LE_COMBINE_BOTTOM(N) _LE_FUNC_NAME(N,combine_bottom)
#define _LE_COMBINE_BOTTOM_PROTO(IE,N,L,T) \
IE void _LE_COMBINE_BOTTOM(N)(L *_l0, L *_l1)
#define _LE_COMBINE_BOTTOM_DEF(IE,N,L,T) \
_LE_COMBINE_BOTTOM_PROTO(IE,N,L,T)\
{\
    if (_LE_IS_EMPTY(N)(_l1)) return;\
    *_LE_DREF_AP(_l1,T) = _LE_CAST(_l0,T);\
    *_LE_DREF_AP(_l0,T) = _LE_DREF_NEXT(_l1,T);\
    _LE_DREF_AP(_LE_DREF_NEXT(_l1,T),T) = _LE_DREF_AP(_l0,T);\
    _LE_DREF_AP(_l0,T) = _LE_DREF_AP(_l1,T);\
    _LE_RESET(N)(_l1);\
}

#define _LE_APPEND_CHUNK_TOP(N) _LE_FUNC_NAME(N,append_chunk_top)
#define _LE_APPEND_CHUNK_TOP_PROTO(IE,N,E,L,T) \
IE void _LE_APPEND_CHUNK_TOP(N)(L *_l0, _LE_ST(T) *_e0, _LE_ST(T) *_e1)
#define _LE_APPEND_CHUNK_TOP_DEF(IE,N,E,L,T) \
_LE_APPEND_CHUNK_TOP_PROTO(IE,N,E,L,T) \
{\
    LIST_ENTRY_TYPE(T) *list =_LE_CAST(_l0,T),\
                       *start=_LE_CAST(_e0,T),\
                       *end=_LE_CAST(_e1,T);\
    *start->ap=end->next;\
    end->next->ap = start->ap;\
    end->next = list->next;\
    list->next->ap = &end->next;\
    list->next = start;\
    start->ap = &list->next;\
}

/* NOTE: Use gcc -E (or equivilent) to see the boilerplate code generated
         by the following. Use gnu "indent" to make it readable.

         i.e.  gcc -E [target.c] | indent -kr

 Semicolons are used at the end of function definitions to force the
 gnu "indent" tool to recognise the end of a definition.
 Strange formatting artifacts will occur otherwise. */

#define LIST_ENTRY_TYPE_BOILERPLATE(IE,ENAME,T) \
    _LE_NEXT_DEF(IE,ENAME,T);\
    _LE_BEFORE_DEF(IE,ENAME,T);\
    _LE_AFTER_DEF(IE,ENAME,T);\
    _LE_ATTACH_DEF(IE,ENAME,T);\
    _LE_DETACH_DEF(IE,ENAME,T);\
    _LE_SET_NEXT_DEF(IE,ENAME,T)

#define LIST_TYPE_BOILERPLATE(IE,NAME,ENAME,LNAME,T) \
    _LE_BOTTOM_DEF(IE,NAME,LNAME,T);\
    _LE_TOP_DEF(IE,NAME,LNAME,T);\
    _LE_FIRST_DEF(IE,NAME,LNAME,T);\
    _LE_IS_DONE_DEF(IE,NAME,LNAME,T);\
    _LE_IS_EMPTY_DEF(IE,NAME,LNAME,T);\
    _LE_PUSH_DEF(IE,NAME,ENAME,LNAME,T);\
    _LE_POP_DEF(IE,NAME,ENAME,LNAME,T);\
    _LE_LENGTH_DEF(IE,NAME,ENAME,LNAME,T);\
    _LE_RESET_DEF(IE,NAME,LNAME,T);\
    _LE_PREV_DEF(IE,NAME,LNAME,T);\
    _LE_CONTAINS_DEF(IE,NAME,LNAME,T)

/*
    _LE_ENABLE_NULL_DEF(IE,NAME,LNAME,T);\
    _LE_DISABLE_NULL_DEF(IE,NAME,LNAME,T);\

*/

#define LIST_TYPE_EXTRAS_BOILERPLATE(IE,NAME,ENAME,LNAME,T) \
    _LE_APPEND_CHUNK_TOP_DEF(IE,NAME,ENAME,LNAME,T);\
    _LE_COMBINE_TOP_DEF(IE,NAME,LNAME,T);\
    _LE_COMBINE_BOTTOM_DEF(IE,NAME,LNAME,T)

#define LIST_ENTRY_TYPE_PROTO(IE,ENAME,T) \
    _LE_NEXT_PROTO(IE,ENAME,T);\
    _LE_BEFORE_PROTO(IE,ENAME,T);\
    _LE_AFTER_PROTO(IE,ENAME,T);\
    _LE_ATTACH_PROTO(IE,ENAME,T);\
    _LE_DETACH_PROTO(IE,ENAME,T);\
    _LE_SET_NEXT_PROTO(IE,ENAME,T)

#define LIST_TYPE_PROTO(IE,NAME,ENAME,LNAME,T) \
    _LE_BOTTOM_PROTO(IE,NAME,LNAME,T);\
    _LE_TOP_PROTO(IE,NAME,LNAME,T);\
    _LE_FIRST_PROTO(IE,NAME,LNAME,T);\
    _LE_IS_DONE_PROTO(IE,NAME,LNAME,T);\
    _LE_IS_EMPTY_PROTO(IE,NAME,LNAME,T);\
    _LE_PUSH_PROTO(IE,NAME,ENAME,LNAME,T);\
    _LE_POP_PROTO(IE,NAME,ENAME,LNAME,T);\
    _LE_LENGTH_PROTO(IE,NAME,ENAME,LNAME,T);\
    _LE_RESET_PROTO(IE,NAME,LNAME,T);\
    _LE_PREV_PROTO(IE,NAME,LNAME,T);\
    _LE_CONTAINS_PROTO(IE,NAME,LNAME,T)

/*

    _LE_ENABLE_NULL_PROTO(IE,NAME,LNAME,T);\
    _LE_DISABLE_NULL_PROTO(IE,NAME,LNAME,T);\

*/

#define LIST_TYPE_EXTRAS_PROTO(IE,NAME,ENAME,LNAME,T) \
    _LE_APPEND_CHUNK_TOP_PROTO(IE,NAME,ENAME,LNAME,T);\
    _LE_COMBINE_TOP_PROTO(IE,NAME,LNAME,T);\
    _LE_COMBINE_BOTTOM_PROTO(IE,NAME,LNAME,T)

