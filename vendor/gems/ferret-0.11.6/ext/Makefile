
SHELL = /bin/sh

#### Start of system configuration section. ####

srcdir = .
topdir = /usr/local/lib/ruby/1.8/x86_64-linux
hdrdir = $(topdir)
VPATH = $(srcdir):$(topdir):$(hdrdir)
prefix = $(DESTDIR)/usr/local
exec_prefix = $(prefix)
sitedir = $(prefix)/lib/ruby/site_ruby
rubylibdir = $(libdir)/ruby/$(ruby_version)
docdir = $(datarootdir)/doc/$(PACKAGE)
dvidir = $(docdir)
datarootdir = $(prefix)/share
archdir = $(rubylibdir)/$(arch)
sbindir = $(exec_prefix)/sbin
psdir = $(docdir)
localedir = $(datarootdir)/locale
htmldir = $(docdir)
datadir = $(datarootdir)
includedir = $(prefix)/include
infodir = $(datarootdir)/info
sysconfdir = $(prefix)/etc
mandir = $(datarootdir)/man
libdir = $(exec_prefix)/lib
sharedstatedir = $(prefix)/com
oldincludedir = $(DESTDIR)/usr/include
pdfdir = $(docdir)
sitearchdir = $(sitelibdir)/$(sitearch)
bindir = $(exec_prefix)/bin
localstatedir = $(prefix)/var
sitelibdir = $(sitedir)/$(ruby_version)
libexecdir = $(exec_prefix)/libexec

CC = gcc
LIBRUBY = $(LIBRUBY_A)
LIBRUBY_A = lib$(RUBY_SO_NAME)-static.a
LIBRUBYARG_SHARED = -Wl,-R -Wl,$(libdir) -L$(libdir) -L. 
LIBRUBYARG_STATIC = -l$(RUBY_SO_NAME)-static

RUBY_EXTCONF_H = 
CFLAGS   =  -fPIC -g -O2 -D_FILE_OFFSET_BITS=64 
INCFLAGS = -I. -I$(topdir) -I$(hdrdir) -I$(srcdir)
CPPFLAGS =  
CXXFLAGS = $(CFLAGS) 
DLDFLAGS =  -rdynamic -Wl,-export-dynamic  
LDSHARED = $(CC) -shared
AR = ar
EXEEXT = 

RUBY_INSTALL_NAME = ruby
RUBY_SO_NAME = ruby
arch = x86_64-linux
sitearch = x86_64-linux
ruby_version = 1.8
ruby = /usr/local/bin/ruby
RUBY = $(ruby)
RM = rm -f
MAKEDIRS = mkdir -p
INSTALL = /usr/bin/install -c
INSTALL_PROG = $(INSTALL) -m 0755
INSTALL_DATA = $(INSTALL) -m 644
COPY = cp

#### End of system configuration section. ####

preload = 

libpath = $(libdir)
LIBPATH =  -L'$(libdir)' -Wl,-R'$(libdir)'
DEFFILE = 

CLEANFILES = 
DISTCLEANFILES = 

extout = 
extout_prefix = 
target_prefix = 
LOCAL_LIBS = 
LIBS =   -lpthread -ldl -lcrypt -lm   -lc
SRCS = stem_ISO_8859_1_porter.c term_vectors.c similarity.c stem_UTF_8_danish.c utilities.c stem_ISO_8859_1_norwegian.c posh.c stem_ISO_8859_1_swedish.c stem_KOI8_R_russian.c array.c stem_ISO_8859_1_portuguese.c r_analysis.c stem_UTF_8_finnish.c bitvector.c q_match_all.c priorityqueue.c sort.c r_qparser.c q_filtered_query.c r_store.c q_const_score.c helper.c stem_UTF_8_german.c stem_UTF_8_french.c q_term.c stem_ISO_8859_1_german.c q_boolean.c r_search.c stem_ISO_8859_1_english.c hashset.c stem_UTF_8_spanish.c store.c fs_store.c global.c index.c stem_UTF_8_porter.c q_fuzzy.c stem_UTF_8_dutch.c stem_UTF_8_russian.c libstemmer.c r_utils.c q_multi_term.c stem_ISO_8859_1_spanish.c stem_UTF_8_english.c ferret.c hash.c compound_io.c q_range.c stem_ISO_8859_1_danish.c stem_UTF_8_italian.c q_phrase.c q_prefix.c analysis.c multimapper.c r_index.c stem_ISO_8859_1_finnish.c ram_store.c stem_ISO_8859_1_italian.c search.c q_span.c api.c document.c q_parser.c mempool.c stem_UTF_8_portuguese.c stopwords.c except.c stem_ISO_8859_1_french.c stem_ISO_8859_1_dutch.c filter.c stem_UTF_8_norwegian.c q_wildcard.c stem_UTF_8_swedish.c
OBJS = stem_ISO_8859_1_porter.o term_vectors.o similarity.o stem_UTF_8_danish.o utilities.o stem_ISO_8859_1_norwegian.o posh.o stem_ISO_8859_1_swedish.o stem_KOI8_R_russian.o array.o stem_ISO_8859_1_portuguese.o r_analysis.o stem_UTF_8_finnish.o bitvector.o q_match_all.o priorityqueue.o sort.o r_qparser.o q_filtered_query.o r_store.o q_const_score.o helper.o stem_UTF_8_german.o stem_UTF_8_french.o q_term.o stem_ISO_8859_1_german.o q_boolean.o r_search.o stem_ISO_8859_1_english.o hashset.o stem_UTF_8_spanish.o store.o fs_store.o global.o index.o stem_UTF_8_porter.o q_fuzzy.o stem_UTF_8_dutch.o stem_UTF_8_russian.o libstemmer.o r_utils.o q_multi_term.o stem_ISO_8859_1_spanish.o stem_UTF_8_english.o ferret.o hash.o compound_io.o q_range.o stem_ISO_8859_1_danish.o stem_UTF_8_italian.o q_phrase.o q_prefix.o analysis.o multimapper.o r_index.o stem_ISO_8859_1_finnish.o ram_store.o stem_ISO_8859_1_italian.o search.o q_span.o api.o document.o q_parser.o mempool.o stem_UTF_8_portuguese.o stopwords.o except.o stem_ISO_8859_1_french.o stem_ISO_8859_1_dutch.o filter.o stem_UTF_8_norwegian.o q_wildcard.o stem_UTF_8_swedish.o
TARGET = ferret_ext
DLLIB = $(TARGET).so
EXTSTATIC = 
STATIC_LIB = 

RUBYCOMMONDIR = $(sitedir)$(target_prefix)
RUBYLIBDIR = /home/reeset/libraryfind/branch-0.9/vendor/gems/ferret-0.11.6/lib$(target_prefix)
RUBYARCHDIR = /home/reeset/libraryfind/branch-0.9/vendor/gems/ferret-0.11.6/lib$(target_prefix)

TARGET_SO     = $(DLLIB)
CLEANLIBS     = $(TARGET).so $(TARGET).il? $(TARGET).tds $(TARGET).map
CLEANOBJS     = *.o *.a *.s[ol] *.pdb *.exp *.bak

all:		$(DLLIB)
static:		$(STATIC_LIB)

clean:
		@-$(RM) $(CLEANLIBS) $(CLEANOBJS) $(CLEANFILES)

distclean:	clean
		@-$(RM) Makefile $(RUBY_EXTCONF_H) conftest.* mkmf.log
		@-$(RM) core ruby$(EXEEXT) *~ $(DISTCLEANFILES)

realclean:	distclean
install: install-so install-rb

install-so: $(RUBYARCHDIR)
install-so: $(RUBYARCHDIR)/$(DLLIB)
$(RUBYARCHDIR)/$(DLLIB): $(DLLIB)
	$(INSTALL_PROG) $(DLLIB) $(RUBYARCHDIR)
install-rb: pre-install-rb install-rb-default
install-rb-default: pre-install-rb-default
pre-install-rb: Makefile
pre-install-rb-default: Makefile
$(RUBYARCHDIR):
	$(MAKEDIRS) $@

site-install: site-install-so site-install-rb
site-install-so: install-so
site-install-rb: install-rb

.SUFFIXES: .c .m .cc .cxx .cpp .C .o

.cc.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.cxx.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.cpp.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.C.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.c.o:
	$(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) -c $<

$(DLLIB): $(OBJS)
	@-$(RM) $@
	$(LDSHARED) $(DLDFLAGS) $(LIBPATH) -o $@ $(OBJS) $(LOCAL_LIBS) $(LIBS)



$(OBJS): ruby.h defines.h
