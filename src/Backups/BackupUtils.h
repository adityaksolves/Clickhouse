#pragma once

#include <Parsers/ASTBackupQuery.h>
#include <Interpreters/Context_fwd.h>


namespace DB
{
class IBackup;
class AccessRightsElements;
class DDLRenamingMap;
struct QualifiedTableName;

namespace BackupUtils
{

/// Initializes a DDLRenamingMap from a BACKUP or RESTORE query.
DDLRenamingMap makeRenamingMap(const ASTBackupQuery::Elements & elements);

/// Returns access required to execute BACKUP query.
AccessRightsElements getRequiredAccessToBackup(const ASTBackupQuery::Elements & elements);

/// Checks the definition of a restored table - it must correspond to the definition from the backup.
bool compareRestoredTableDef(const IAST & restored_table_create_query, const IAST & create_query_from_backup, const ContextPtr & global_context);
bool compareRestoredDatabaseDef(const IAST & restored_database_create_query, const IAST & create_query_from_backup, const ContextPtr & global_context);

/// Returns true if this table is an inner table by name, i.e. carries one of the reserved `.inner*`
/// prefixes. Usable wherever only names are available, in particular on the RESTORE path, where the
/// names come out of a backup and the tables they belong to need not exist.
bool isInnerTable(const QualifiedTableName & table_name);
bool isInnerTable(const String & database_name, const String & table_name);

/// Returns true if this table should be skipped while making a backup because it's an inner table
/// backed up through its outer table. On top of `isInnerTable` this recognises inner tables whose
/// names are not reserved and can only be identified by finding the live outer table owning them,
/// so it is meaningful only while making a backup, with `DatabaseCatalog` still holding that table.
bool isInnerTableForBackup(const String & database_name, const String & table_name);

}

}
