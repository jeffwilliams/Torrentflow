%{
#include "libtorrent/file_storage.hpp"
#include "libtorrent/storage.hpp"
%}

namespace libtorrent
{
  class file_storage;

  %rename("STORAGE_MODE_ALLOCATE") storage_mode_allocate;
  %rename("STORAGE_MODE_SPARSE") storage_mode_sparse;
  %rename("STORAGE_MODE_COMPACT") storage_mode_compact;
  enum storage_mode_t
  {
    storage_mode_allocate = 0,
    storage_mode_sparse,
    storage_mode_compact
  };

  class hasher;

  struct partial_hash
  {   
    partial_hash(): offset(0) {} 
    // the number of bytes in the piece that has been hashed
    int offset;
    // the sha-1 context
    hasher h;
  };

	struct storage_interface
	{
		// create directories and set file sizes
		// if allocate_files is true. 
		// allocate_files is true if allocation mode
		// is set to full and sparse files are supported
		virtual void initialize(bool allocate_files) = 0;

		// may throw file_error if storage for slot does not exist
		virtual size_type read(char* buf, int slot, int offset, int size) = 0;

		// may throw file_error if storage for slot hasn't been allocated
		virtual void write(const char* buf, int slot, int offset, int size) = 0;

#if LIBTORRENT_VERSION_MINOR <= 15
		virtual bool move_storage(boost::filesystem::path save_path) = 0;
#elif LIBTORRENT_VERSION_MINOR > 15
    virtual bool move_storage(std::string const& save_path) = 0;
#endif

		// write storage dependent fast resume entries
		virtual void write_resume_data(entry& rd) const = 0;

		// moves (or copies) the content in src_slot to dst_slot
		virtual void move_slot(int src_slot, int dst_slot) = 0;

		// swaps the data in slot1 and slot2
		virtual void swap_slots(int slot1, int slot2) = 0;

		// swaps the puts the data in slot1 in slot2, the data in slot2
		// in slot3 and the data in slot3 in slot1
		virtual void swap_slots3(int slot1, int slot2, int slot3) = 0;

		// this will close all open files that are opened for
		// writing. This is called when a torrent has finished
		// downloading.
		virtual void release_files() = 0;

		// this will close all open files and delete them
		virtual void delete_files() = 0;

		virtual ~storage_interface() {}
	};

	//typedef storage_interface* (&storage_constructor_type)( boost::intrusive_ptr<torrent_info const>, fs::path const&, file_pool&);
	typedef storage_interface* (*storage_constructor_type)( boost::intrusive_ptr<torrent_info const>, boost::filesystem::path const&, file_pool&);

  struct file_pool;

}
