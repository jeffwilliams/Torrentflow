%{
#include "libtorrent/entry.hpp"
%}

%include std_map.i

namespace libtorrent {


  class entry
  {
  public:

    typedef std::map<std::string, entry> dictionary_type;
    typedef std::string string_type;
    typedef std::list<entry> list_type;
    typedef size_type integer_type;

    %rename("INTEGER") int_t;
    %rename("STRING") string_t;
    %rename("LIST") list_t;
    %rename("DICTIONARY") dictionary_t;
    %rename("UNDEFINED") undefined_t;
    enum data_type
    {
      int_t,
      string_t,
      list_t,
      dictionary_t,
      undefined_t
    };

    data_type type() const;

    entry(const dictionary_type&);
    entry(const string_type&);
    entry(const list_type&);
    entry(const integer_type&);

    entry();
    entry(data_type t);
    entry(const entry& e);
    ~entry();

    bool operator==(entry const& e) const;

    integer_type& integer();
    const integer_type& integer() const;
    string_type& string();
    const string_type& string() const;
    list_type& list();
    const list_type& list() const;
    dictionary_type& dict();
    const dictionary_type& dict() const;

    entry* find_key(const char* key);
    entry const* find_key(const char* key) const;

    %extend {
      const entry __getitem__(const std::string& key) const {
        return (*self)[key];
      }

      void __setitem__(const std::string& key, entry e) {
        (*self)[key] = e;
      }

      static libtorrent::entry load(const char* path) const {
        return load_entry(path);
      }

      void save(const char* path) const {
        save_entry(*self, path);
      }
    }
  };

}
