require "pg"
# require "pry"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "todos")
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1;"
    result = query(sql, id)

    tuple = result.first
    list_id = tuple['id'].to_i
    todos = find_todos_for_list(list_id)

    {id: list_id, name: tuple['name'], todos: todos}
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)

    result.map do |tuple|
      list_id = tuple['id'].to_i
      todos = find_todos_for_list(list_id)
      {id: list_id, name: tuple['name'], todos: todos}
    end
  end

  def create_new_list(name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, name)
  end

  def delete_list(id)
    todo_sql = "DELETE FROM todos WHERE list_id = $1;"
    list_sql = "DELETE FROM lists WHERE id = $1;"
    query(todo_sql, id)
    query(list_sql, id)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2;"
    query(sql, new_name, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (list_id, name) VALUES ($1, $2);"
    query(sql, list_id, todo_name)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE list_id = $1 AND id = $2;"
    query(sql, list_id, todo_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE list_id = $2 AND id = $3;"
    query(sql, new_status, list_id, todo_id)
  end

  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1;"
    query(sql, list_id)
  end

  private

  def find_todos_for_list(list_id)
    todos_sql = "SELECT * FROM todos WHERE list_id = $1;"
    todos_result = query(todos_sql, list_id)

    todos_result.map do |todo_tuple|
      { id: todo_tuple['id'].to_i,
        name: todo_tuple['name'],
        completed: todo_tuple['completed'] == 't'
      }
    end
  end
end
