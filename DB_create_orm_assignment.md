1. **What's a RubyGem and why would you use one?**
   - A RubyGem, not to be confused with _RubyGems_, is a library that can be added to a project to add functionality to an application.  We use gems to add desired functionality to our app without needing to "recreate the wheel".  For example, we may decide to use the _Devise_ Gem to add a method for authentication in our app, instead of creating a system from scratch.
2. **What's the difference between lazy and eager loading?**
   - Lazy Loading does not load data until such data is needed.  In the example below, the `Post` table is lazy loaded.  We don't query the database until we need the data.
     ```
     @topic = Topic.find_by(23)
     ...
     @topic.posts.first
     ```
   - Eager Loading loads data first, and holds it until needed.  In the example below, the `Post` table is joined with `Topic` and the joined table is stored in `@topic` and held until needed.
     ```
     @topic = Topic.joins(:post).where(topic.post_id = post.id)
     ...
     @topic.posts.first
     ```
3. **What's the difference between the `CREATE TABLE` and `INSERT INTO` SQL statements?**
   - The `CREATE TABLE` statement creates a new table in the database
   - The `INSERT INTO` statement inserts data into the specified table

4. **What's the difference between `extend` and `include`? When would you use one or the other?**
   - **Extend**
    - The `extend` option will make the methods of the module available to the `class` itself.  These will need to be called from the class, not an instance of the class.  The following code will cause a `NoMethodError` when used with an _instance_ of the `ToExtend` class.  This must be called by referencing the `class` itself, such as `ToExtend.hello_world`.
      ```ruby
      module PrintGreeting
        def hello_world
          puts 'Hello World!'
        end
      end

      class ToExtend
        extend PrintGreeting
      end
      ```
   - **Include**
     - The `include` option will make the methods of the module available to instances of the class, but not the class itself.  These methods will need to be called from the instantiated instance of the class.  The following sample code, we would log `Hello World` to the console:
      ```ruby
      module PrintGreeting
        def hello_world
          puts 'Hello World!'
        end
      end

      class ToInclude
        include PrintGreeting
      end

      to_include = ToInclude.new
      to_include.hello_world

      # The following causes a 'NoMethodError'
      ToInclude.hello_world
      ```
5. **In `persistence.rb`, why do the `save` methods need to be _instance_ (vs. _class_) methods?**
   - We establish the `save` methods as _instance_ methods so we can save each individual instance of the database (i.e. `persist.save!`).  If it was created as a _class_ method, we would need to pass in the object we want to save, which could get a lot more convoluted (i.e. `Persistence.save(obj)`).


6. **Given the Jar-Jar Binks example earlier, what is the final SQL query in `persistence.rb`'s `save!` method?**
   - **Note To Grader:**
     > I'm not sure what is requested for here.  The final SQL query in `save!` is an `UPDATE` statement, and the `Jar-Jar Binks` examples do not update anything, instead they create.  My theory is that by omitting the `ID`, it will divert to `save` and create a new object that will then be saved.  If that is the case, would we still call `UPDATE`, or should the answer for this question be an `INSERT` statement that follows the proper way to insert data into an SQL database?

   - **SQL Query**
     ```SQL
     UPDATE character
        SET name="Jar-Jar Binks", rating=1;
     ```

7. **`AddressBook`'s `entries` instance variable no longer returns anything. We'll fix this in a later checkpoint. What changes will we need to make?**
   - I'm not certain but it doesn't look like we instantiate the `Entry` class from `entry.rb`.  We do have a `require` for it in `address_book.rb`, but since `to_s` is an instance method, shouldn't we instantiate an instance of the class?
---

### Programming Questions
1. **Write a Ruby method that converts `snake_case` to `CamelCase` using regular expressions (you can test them on Rubular). Send your code in the submission tab.**
   - ```ruby
     def camel_case(string)
       string.gsub(/(?:_|^)(\w)/){$1.upcase}
     end
     ```
2. **Add a select method which takes an attribute and value and searches for all records that match:**
   - `lib/bloc_record/selection.rb`
     ```ruby
     def find_by(attribute, value)
       row = connection.get_first_row <<-SQL
         SELECT #{columns.join ", "}
           FROM #{table}
          WHERE #{attribute} = #{value};
       SQL
     end
     ```
   > **Assuming you have an `AddressBook`, it might get called like this:**
   > ```ruby
   > myAddressBook = AddressBook.find_by("name", "My Address Book")
   > ```
   > **Your code should use a `SELECT…WHERE` SQL query and return an array of objects to the caller. Send your code in the submission tab.**
