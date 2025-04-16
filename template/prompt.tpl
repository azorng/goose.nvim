<? if current_file or mentioned_files or selections then ?>
  <additional-data>
    Below is context that may help answer the user query. Ignore if not relevant
    <? if current_file then ?>
      <current-file>
        Path: <%= current_file.path %>
        Line: <%= cursor_data.line %>
        Line Content: <%= cursor_data.line_content %>
      </current-file>
    <? end ?>
    <? if selections or mentioned_files then ?>
      <attached-files>
        <? if selections then ?>
          <? for x, selection in ipairs(selections) do ?>
            <manually-added-selection>
              <? if selection.file then ?>
                ```<%= selection.file.extension %> <%= selection.file.name %> (lines <%= selection.lines %>)
                  <%= selection.content %>
                ```
              <? else ?>
                ```
                  <%= selection.content %>
                ```
              <? end ?>
            </manually-added-selection>
          <? end ?>
        <? end ?>
        <? if mentioned_files then ?>
          <? for x, path in ipairs(mentioned_files) do ?>
            <mentioned-file>
              Path: <%= path %>
            </mentioned-file>
          <? end ?>
        <? end ?>
      </attached-files>
    <? end ?>
  </additional-data>
  <user-query>
    <%= prompt %>
  </user-query>
<? else ?>
  <%= prompt %>
<? end ?>
