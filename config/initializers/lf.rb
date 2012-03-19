#========================================================================
# Create some text based constants
#========================================================================
LIBRARYFIND_LOCAL = 1
LIBRARYFIND_WSDL_ENGINE = 0
LIBRARYFIND_SFX = 2
LIBRARYFIND_SS = 3

require 'yaml'
require 'dalli'

yp = YAML::load_file(RAILS_ROOT + "/config/config.yml")
CFG_LF_URL_BASE = yp['CFG_LF_URL_BASE']
CFG_LF_TIMEOUT = yp['CFG_LF_TIMEOUT']
CFG_LF_TIMEOUT_SOLR = yp['CFG_LF_TIMEOUT_SOLR']

#========================================================================
# LIBRARYFIND_BASEURL: Sets the base url
#    Description:  This is used to set the Proxy info
#  / END SLASH IMPORTANT
#========================================================================
LIBRARYFIND_BASEURL = CFG_LF_URL_BASE

#========================================================================
# LIBRARYFIND_PROCESS_TIMEOUT: Sets timeout property for connections that
# require it
#========================================================================
LIBRARYFIND_PROCESS_TIMEOUT = CFG_LF_TIMEOUT

#========================================================================
# LIBRARYFIND_PROXY_TYPE: Sets the proxy type
#     which is used for determining proxy styles.
#     value:
#          WAM -- III's proxy setup
#          EZPROXY -- EZPROXY's proxy url setup
#          NONE -- No proxy
#========================================================================
LIBRARYFIND_PROXY_TYPE = "NONE"

#========================================================================
# LIBRARYFIND_PROXY_ADDRESS: Sets proxy address for use when writing
#     WAM or Ezproxy URLS
#     Description: Used for generating proxy info
#======================================================================== 
LIBRARYFIND_PROXY_ADDRESS = 'http://proxy.library.oregonstate.edu/login?url='

#========================================================================

#========================================================================
# LIBRARYFIND_USE_PROXY: Uses proxy generation
#   Value: true, false
#========================================================================
LIBRARYFIND_USE_PROXY = false


#=======================================================================
# LIBRARYFIND_OFFER_LOGIN: 
# Value: true, false
# Description: Set this value if you want to offer proxy authentication
# for private resources
#=======================================================================
LIBRARYFIND_OFFER_LOGIN = false


#========================================================================
# LIBRARYFIND_IS_SERVER: Denotes if application is a wsdl producer
#   Values: true -- Does serve WSDL
#           false -- Does not server WSDL
#========================================================================
LIBRARYFIND_IS_SERVER = true

#=========================================================================
# LIBRARYFIND_WSDL:  Denotes if search is done locally or through a WSDL
#                    interface
#
#Enum for LIBRARYFIND_WSDL
# LIBRARYFIND_WSDL_ENGINE
# LIBRARYFIND_LOCAL
#==========================================================================
LIBRARYFIND_WSDL = LIBRARYFIND_LOCAL

#===========================================================================
# LIBRARYFIND_OPENURL_TYPE: Denotes look ahead options.  Current options
#                           available: LIBRARYFIND_LOCAL or LIBRARYFIND_SFX
# Enum for LIBRARYFIND_OPENURL_TYPE
#  LIBRARYFIND_LOCAL
#  LIBRARYFIND_SFX
#  LIBRARYFIND_SS
#  LIBRARYFIND_GD  (Gold Dust Link Resolver)
#===========================================================================
LIBRARYFIND_OPENURL_TYPE = LIBRARYFIND_LOCAL

#============================================================================
# LIBRARYFIND_OPENURL: Defines OpenURL base for queries.  This can be any
#                      openurl resolver that supports OpenURL 1.0
#============================================================================
LIBRARYFIND_OPENURL = LIBRARYFIND_BASEURL + 'openurl/resolve?'

#=========================================================================
# LIBRARYFIND_EMAIL_USER:  Email address from which LibraryFind mail will
#                                                  be sent (e.g. for emailing selected search results)
#   Example:
#   LIBRARYFIND_EMAIL_USER = 'LFadmin@myuniversity.edu'
#=========================================================================
LIBRARYFIND_EMAIL_USER = yp['SMTP_MAIL_EMETTEUR']

# State for cached_records
LIBRARYFIND_CACHE_OK = 0
LIBRARYFIND_CACHE_EMPTY = 1
LIBRARYFIND_CACHE_ERROR = 2

# State for JobQueue
JOB_WAITING = 1
JOB_FINISHED = 0
JOB_ERROR = -1
JOB_PRIVATE = -2
JOB_STOPPED = -3
JOB_ERROR_TYPE = -4

# URL SOLR
LIBRARYFIND_FERRET_PATH = yp['LIBRARYFIND_FERRET_PATH']
LIBRARYFIND_SOLR_HOST = yp['LIBRARYFIND_SOLR_HOST']
LIBRARYFIND_SOLR_HARVESTING_URL = yp['LIBRARYFIND_SOLR_HARVESTING_URL']

LIBRARYFIND_INDEXER = yp['LIBRARYFIND_INDEXER']
PARSER_TYPE = yp['PARSER_TYPE']
NB_RESULTAT_MAX = yp['NB_RESULTAT_MAX']
MAX_COLLECTION_SEARCH = yp['MAX_COLLECTION_SEARCH']
#LIBRARYTHING_DEVKEY = yp['LIBRARYTHING_DEVKEY']
#OPENLIBRARY_COVERS = yp['OPENLIBRARY_COVERS']
#GOOGLE_COVERS = yp['GOOGLE_COVERS']

# Extract the ILL Link Associated with LibraryFind
LIBRARYFIND_ILL = yp['ILL_URL']

CROSSREF_ID = "osul:osul1211"
DOI_SERVLET = "http://doi.crossref.org/servlet/query?id={@DOI}&pid=" + CROSSREF_ID
YAHOO_APPLICATION_ID = 'QlxYkgvV34EfBvtpTxwm160eWujk1advwfSZCHllZQUyQJf8PanUbw7dcJPJfLJlOpdWyhYNcKavKPST'


LIBRARYFIND_OCLC_SYMBOL= 'ORE'
LIBRARYFIND_SERVER_IP = '128.193.163.0'
LIBRARYFIND_IP_RANGE = '128.193.;10.;140.211.24.;'

ActiveRecord::Base.allow_concurrency  = true
ActiveRecord::Base.verification_timeout  = 590

# Param for GED Connector
GED_URL_SEPARATOR = yp['GED_URL_SEPARATOR']
GED_URL_PATH = yp['GED_URL_PATH']
GED_NB_CAR_REP = yp['GED_NB_CAR_REP']
GED_NAME_FILE = yp['GED_NAME_FILE']

LINK_SATISFACTION_URL = yp['LINK_SATISFACTION_URL']
LINK_MESSAGERIE_URL = yp['LINK_MESSAGERIE_URL']

# Set true, for log statistics
# Your debugger must be set to WARN
LOG_STATS = true

web = YAML::load_file(RAILS_ROOT + "/config/webservice.yml")
# PROXY HTTP
ENV['PROXY_URL'] = web['PROXY_HTTP_ADR'].to_s
ENV['PROXY_PORT'] = web['PROXY_HTTP_PORT'].to_s

SEE_ALSO_ACTIVATE = yp['SEE_ALSO_ACTIVATE']
SEE_ALSO_MAX = yp['SEE_ALSO_MAX'].to_i

# SpellCheck Constant
SPELL_ACTIVATE = yp["SPELL_ACTIVATE"]
SPELL_COUNT = yp['COUNT']

# Themes
THEME_ACTIVATE = true
THEME_SEPARATOR = " > "

# Location of log file statistic
LOG_FILE_LOCATION = yp["LOG_FILE_LOCATION"]
LOG_NAME_FILE     = yp["LOG_NAME_FILE"]

# Separator in url filter
FILTER_SEPARATOR = "#"

ID_SEPARATOR = ";"

RSS_TIMEOUT = 30

DEFAULT_PAGE_NUMBER_COMMENT = 0;

DEFAULT_MAX_COMMENT = 20;

DEFAULT_PAGE_NUMBER_OBJECT = 0;

DEFAULT_MAX_OBJECT = 20;

DEFAULT_PAGE_NUMBER_TAG = 0;

DEFAULT_PAGE_LIST = 0;

DEFAULT_MAX_LIST = 20;

DEFAULT_MAX_TAG = 20;

DEFAULT_MAX_NOTICE = 20;

DEFAULT_PAGE_NUMBER_NOTICE = 0;

COMMENT_VALIDATED = 1;

COMMENT_NOT_VALIDATED = 0;

TAG_VALIDATED = 1;

TAG_NOT_VALIDATED = 0;

COMMENT_RELEVANT = 2;

COMMENT_NOT_RELEVANT = 1;
# id widget set
WIDGET_SETS = yp['WIDGET_SETS']

#ldap = YAML::load_file(RAILS_ROOT + "/config/ldap.yml")
#LDAP_ENABLE = ldap["LDAP_ENABLE"]


SORT_TYPE = "type"
SORT_AUTHOR = "author"
SORT_TITLE = "title"
SORT_DATE = "date"
SORT_RELEVANCE = "relevance"
SORT_TAG_RELEVANCE = "tag_weight"
DIRECTION_UP = "up"
DIRECTION_DOWN = "down"

SORT_TAG_RANDOM = "RAND()"
SORT_TAG_ALPHABETIC = "label"

LIST_PRIVATE = 0
LIST_PUBLIC = 1

COMMENT_PRIVATE = 0
COMMENT_PUBLIC = 1

TAG_PRIVATE = 0
TAG_PUBLIC = 1

WORKFLOW_COMMENT_VALIDATION = 0

WORKFLOW_TAG_VALIDATION = 0

MULTIPLE_COMMENTS = 1

ENUM_NOTICE = 1

ENUM_LIST = 2

ENUM_COMMENT = 3

ENUM_TAG = 4

ENUM_COMMUNITY_USER = 5

ENUM_SUBSCRIPTION = 6

ENUM_RSS_FEED = 7

ENUM_SEARCH_HISTORY = 8

MAX_NOTICES = 25

#log action type
PRINT_ACT = 1
MAIL_ACT = 2
CONSULT_ACT = 3
TAG_ACT = 4
NOTE_ACT = 5
COMMENT_ACT = 6
EXPORT_ACT = 7
#

#log notice save in
LIST_SAVE = 1
CART_SAVE = 2
MY_DOC_SAVE = 3
#

#movement type
ADD_ACT = 1
DELETE_ACT = 0
#

DEFAULT_IMAGE = 'public/images/no_image.jpg'

ACCESS_ALLOWED = 'ACC'

# Set false, if no variable in header http
INFOS_USER_CONTROL = true

BASIC_ROLE = "basic"

ANONYM_ROLE = "anonym"

MAIL_NOTIFICATION = 1

NO_MAIL_NOTIFICATION = 0

ACTIVE_SUBSCRIPTION = 1

INACTIVE_SUBSCRIPTION = 0

DONT_LIKE_COMMENT = -1

LIKE_COMMENT = 1

SUBSCRIPTION_ACTIVE = 0

SUBSCRIPTION_NOTIFIED = 1

SUBSCRIPTION_FINISHED = 2

DEFAULT_PRIVACY_PRIVATE = 0

DEFAULT_PRIVACY_PUBLIC = 1

DEFAULT_SUBSCRIBED = 1

DEFAULT_NOT_SUBSCRIBED = 0

DEFAULT_MAIL_NOTIFIED = 1

DEFAULT_MAIL_NOT_NOTIFIED = 0

DEFAULT_RESULTS_NUMBER = 25

DEFAULT_SORT_VALUE = "relevance"

NEW_DOCS = 1

NOT_NEW_DOCS = 0

ISBN_ISSN_NULL = 0

ISBN_ISSN_NOT_NULL = 1

DEFAULT_SEARCH_TYPE = "keyword"

DEFAULT_SEARCH_GROUP = "g6"

DEFAULT_SEARCH_TAB = 1


# Plateform
AMD64 = yp['AMD64']

PROFIL_HTTP = "HTTP_LOCATION_USER"

# Config MemCached
CACHE_ACTIVATE = true
#CACHE = MemCache.new('127.0.0.1', { :timeout => 1.0, :multithread=>true, :compression=>true })
servers = yp["MEMCACHED_SERVERS"].split(",")
ActiveRecord::Base.logger.debug("INIT MEMCACHE #{servers.inspect}")
CACHE = Dalli::Client.new(servers, {:threadsafe=>true,:failover=>true,:socket_max_failures=>4, :down_retry_delay=>1, :compression=>true,:value_max_bytes=>5000000 })

# Access groups that does not require workstation resercation
FREE_ACCESS_GROUPS = yp['FREE_ACCESS_GROUPS']
