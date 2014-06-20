# -*- encoding : utf-8 -*-
require 'actionpack'
class NotifierHook < Redmine::Hook::Listener

  def controller_issues_new_after_save(context = { })
    @project = context[:project]
    @issue = context[:issue]
    @author = @issue.author
    @channel = project_to_channel(@project.name)
    @assigned_message = @issue.assigned_to.nil? ? "No-one" : "#{@issue.assigned_to.firstname} #{@issue.assigned_to.lastname}"
    speak "##{@channel} #{@author.firstname} #{@author.lastname} Created a new Issue:「#{@issue.subject}」"
    speak "##{@channel} Status:「#{@issue.status.name}」. Assigned to:「#{@assigned_message}」. description:「#{truncate_words(@issue.description)}」"
    speak "##{@channel} url: https://#{Setting.host_name}/issues/#{@issue.id}"
  end

  def controller_issues_edit_before_save(context = { })
    @project = context[:project]
    @issue = context[:issue]
    @journal = context[:journal]
    @editor = @journal.user
    @assigned_message = issue_assigned_changed?(@issue)
    @status_message = issue_status_changed?(@issue)
    speak "##{@channel} #{@editor.firstname} #{@editor.lastname} edited:「#{@issue.subject}」"
    speak "##{@channel} Status:「#{@status_message}」. Assigned to:「#{@assigned_message}」. description:「#{truncate_words(@journal.notes)}」"
    speak "##{@channel} url: https://#{Setting.host_name}/issues/#{@issue.id}"
  end

  def controller_messages_new_after_save(context = { })
    @project = context[:project]
    @message = context[:message]
    @author = @message.author
    speak "##{@channel} #{@author.firstname} #{@author.lastname} wrote a new message「#{@message.subject}」on #{@project.name}:「#{truncate_words(@message.content)}」"
    speak "##{@channel} url: https://#{Setting.host_name}/boards/#{@message.board.id}/topics/#{@message.root.id}#message-#{@message.id}"
  end

  def controller_messages_reply_after_save(context = { })
    @project = context[:project]
    @message = context[:message]
    @author = @message.author
    speak "##{@channel} #{@author.firstname} #{@author.lastname} replied a message「#{@message.subject}」on #{@project.name}: 「#{truncate_words(@message.content)}」"
    speak "##{@channel} url: https://#{Setting.host_name}/boards/#{@message.board.id}/topics/#{@message.root.id}#message-#{@message.id}"
  end

  def controller_wiki_edit_after_save(context = { })
    @project = context[:project]
    @page = context[:page]
    @author = @page.content.author
    speak "##{@channel} #{@author.firstname} #{@author.lastname} edited the wiki page「#{@page.pretty_title}」on #{@project.name}."
    speak "##{@channel} url: https://#{Setting.host_name}/projects/#{@project.identifier}/wiki/#{@page.title}"
  end

private

  def project_to_channel(project)
  	# XXX this should be in a config file somewhere.
  	map = Hash.new("#emfcamp-test")
    map["Noc"] = "#emfcamp-noc"
    map["Test"] = "#emfcamp-test"
    map["sysadmin"] = "#emfcamp-test,@jasperw"
    map[project]
  end

  def speak(message)
    system("echo -n '#{message.delete("[\"\']")}' | nc -q0 localhost 12345")
  end

  def truncate_words(text, length = 20, end_string = '…')
    return if text == nil
    words = text.split()
    words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
  end

  def issue_status_changed?(issue)
    if issue.status_id_changed?
      old_status = IssueStatus.find(issue.status_id_was)
      "changed from #{old_status.name} to #{issue.status.name}"
    else
      "#{issue.status.name}"
    end
  end

  def issue_assigned_changed?(issue)
    if issue.assigned_to_id_changed?
      old_assigned_to = User.find(issue.assigned_to_id_was) rescue nil
      old_assigned = old_assigned_to.nil? ? "no-one" : "#{old_assigned_to.firstname} #{old_assigned_to.lastname}"
      new_assigned = issue.assigned_to.nil? ? "no-one" : "#{issue.assigned_to.firstname} #{issue.assigned_to.lastname}"
      "from #{old_assigned} to #{new_assigned}"
    else
      issue.assigned_to.nil? ? "no-one" : "#{issue.assigned_to.firstname} #{issue.assigned_to.lastname}"
    end
  end

end
