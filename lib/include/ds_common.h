
#pragma once

/* macros for previous node cyclic list, next node null terminating list */

#define pcnnt_remove(HEAD, TARGET) \
    do {\
        if (*(HEAD) == (TARGET)) {\
            *(HEAD) = (TARGET)->next;\
            if ((TARGET)->next) (TARGET)->next->prev = (TARGET)->prev;\
        } else {\
            (TARGET)->prev->next = (TARGET)->next;\
            if ((TARGET)->next) (TARGET)->next->prev = (TARGET)->prev;\
            else (*(HEAD))->prev = (TARGET)->prev;\
        }\
    } while(0)

#define pcnnt_insert(HEAD, TARGET) \
    do {\
        if (*(HEAD)) { \
            (TARGET)->prev = (*(HEAD))->prev;\
            (TARGET)->next = *(HEAD);\
            *(HEAD) = (TARGET);\
        } else {\
            (TARGET)->next = NULL;\
            (TARGET)->prev = (TARGET);\
             *(HEAD) = (TARGET);\
        }\
    } while(0)

#define pcnnt_insert_tail(HEAD, TARGET) \
    do {\
        if (*(HEAD)) { \
            (TARGET)->prev = (*(HEAD))->prev;\
            (TARGET)->prev->next = (TARGET);\
            (TARGET)->next = NULL;\
            *(HEAD)->prev = (TARGET);\
        } else {\
            (TARGET)->next = NULL;\
            (TARGET)->prev = (TARGET);\
             *(HEAD) = (TARGET);\
        }\
    } while(0)

/*#define pcnnt_length(TYP_A, TARGET, RESULT) \
    do {\
        (TYP_A) *_ptr = *(ARCHEAD);\
        size_t      _x = 0;\
        if (_ptr) {\
            do _x++;\
            while (_ptr = _ptr->next);\
        }\
        *(XPTR) = _x;\
    } while(0)

    */

     