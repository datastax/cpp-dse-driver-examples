/*
  Copyright (c) 2014 DataStax

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

#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "cassandra.h"

#define NUM_CONCURRENT_REQUESTS 10000

void print_error(CassFuture* future) {
  CassString message = cass_future_error_message(future);
  fprintf(stderr, "Error: %.*s\n", (int)message.length, message.data);
}


CassCluster* create_cluster() {
  CassCluster* cluster = cass_cluster_new();
  CassString contact_points = cass_string_init("127.0.0.1,127.0.0.2");
  cass_cluster_set_contact_points(cluster, contact_points);
  cass_cluster_set_log_level(cluster, CASS_LOG_WARN);
  cass_cluster_set_queue_size_io(cluster, 16384);
  cass_cluster_set_num_threads_io(cluster, 2);
  cass_cluster_set_max_pending_requests(cluster, 10000);
  cass_cluster_set_core_connections_per_host(cluster, 2);
  cass_cluster_set_max_connections_per_host(cluster, 4);
  return cluster;
}

CassError connect_session(CassCluster* cluster, CassSession** output) {
  CassError rc = 0;
  CassFuture* future = cass_cluster_connect_keyspace(cluster, "examples");

  *output = NULL;

  cass_future_wait(future);
  rc = cass_future_error_code(future);
  if(rc != CASS_OK) {
    print_error(future);
  } else {
    *output = cass_future_get_session(future);
  }
  cass_future_free(future);

  return rc;
}

CassError execute_query(CassSession* session, const char* query) {
  CassError rc = 0;
  CassFuture* future = NULL;
  CassStatement* statement = cass_statement_new(cass_string_init(query), 0);

  future = cass_session_execute(session, statement);
  cass_future_wait(future);

  rc = cass_future_error_code(future);
  if(rc != CASS_OK) {
    print_error(future);
  }

  cass_future_free(future);
  cass_statement_free(statement);

  return rc;
}

void insert_into_perf(CassSession* session) {
  size_t i;
  CassString query = cass_string_init("INSERT INTO songs (id, title, album, artist, tags) VALUES (?, ?, ?, ?, ?);");
  CassFuture* futures[NUM_CONCURRENT_REQUESTS];

  static CassCollection* collection = NULL;

  if (collection == NULL) {
    collection = cass_collection_new(CASS_COLLECTION_TYPE_SET, 2);
    cass_collection_append_string(collection, cass_string_init("jazz"));
    cass_collection_append_string(collection, cass_string_init("2013"));
  }

  for(i = 0; i < NUM_CONCURRENT_REQUESTS; ++i) {
    CassUuid id;
    CassStatement* statement = cass_statement_new(query, 5);

    cass_uuid_generate_time(id);
    cass_statement_bind_uuid(statement, 0, id);
    cass_statement_bind_string(statement, 1, cass_string_init("La Petite Tonkinoise"));
    cass_statement_bind_string(statement, 2, cass_string_init("Bye Bye Blackbird"));
    cass_statement_bind_string(statement, 3, cass_string_init("Joséphine Baker"));
    cass_statement_bind_collection(statement, 4, collection);

    futures[i] = cass_session_execute(session, statement);
    cass_statement_free(statement);
  }

  for(i = 0; i < NUM_CONCURRENT_REQUESTS; ++i) {
    CassFuture* future = futures[i];
    CassError rc = cass_future_error_code(future);
    if(rc != CASS_OK) {
      print_error(future);
    }
    cass_future_free(future);
  }
}

void select_from_perf(CassSession* session) {
  int i;
  CassString query = cass_string_init("SELECT * FROM songs LIMIT 3;");
  CassFuture* futures[NUM_CONCURRENT_REQUESTS];

  for(i = 0; i < NUM_CONCURRENT_REQUESTS; ++i) {
    CassStatement* statement = cass_statement_new(query, 0);
    futures[i] = cass_session_execute(session, statement);
    cass_statement_free(statement);
  }

  for(i = 0; i < NUM_CONCURRENT_REQUESTS; ++i) {
    CassFuture* future = futures[i];
    CassError rc = cass_future_error_code(future);
    if(rc != CASS_OK) {
      print_error(future);
    } else {
      const CassResult* result = cass_future_get_result(future);
      assert(cass_result_row_count(result) == 3);
      cass_result_free(result);
    }
    cass_future_free(future);
  }
}

int main() {
  CassError rc = 0;
  CassCluster* cluster = create_cluster();
  CassSession* session = NULL;
  CassFuture* close_future = NULL;

  rc = connect_session(cluster, &session);
  if(rc != CASS_OK) {
    return -1;
  }

  execute_query(session, "CREATE TABLE songs (id uuid PRIMARY KEY, title text, "
                         "album text, artist text, tags set<text>, data blob);");

  insert_into_perf(session);
  select_from_perf(session);

  close_future = cass_session_close(session);
  cass_future_wait(close_future);
  cass_future_free(close_future);
  cass_cluster_free(cluster);

  return 0;
}
