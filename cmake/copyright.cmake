# Single source for the copyright line of every native build (Windows app,
# installer UI, setup engine). The first year is fixed, the last one is the
# build year. string(TIMESTAMP) honours SOURCE_DATE_EPOCH, so reproducible
# builds stay reproducible.
#
# Sets LF_COPYRIGHT, for example "Copyright (C) 2026-2027 LineFM Studios".
set(LF_COPYRIGHT_FIRST_YEAR 2026)
string(TIMESTAMP LF_COPYRIGHT_BUILD_YEAR "%Y" UTC)
if(LF_COPYRIGHT_BUILD_YEAR GREATER LF_COPYRIGHT_FIRST_YEAR)
  set(LF_COPYRIGHT_YEARS "${LF_COPYRIGHT_FIRST_YEAR}-${LF_COPYRIGHT_BUILD_YEAR}")
else()
  set(LF_COPYRIGHT_YEARS "${LF_COPYRIGHT_FIRST_YEAR}")
endif()
set(LF_COPYRIGHT "Copyright (C) ${LF_COPYRIGHT_YEARS} LineFM Studios")
