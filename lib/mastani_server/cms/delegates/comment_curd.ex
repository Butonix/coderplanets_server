defmodule MastaniServer.CMS.Delegate.CommentCURD do
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  import MastaniServer.CMS.Utils.Matcher
  import ShortMaps

  alias MastaniServer.{Repo, Accounts}
  alias Helper.{ORM, QueryBuilder}
  alias MastaniServer.CMS.{PostCommentReply, JobCommentReply}

  @doc """
  Creates a comment for psot, job ...
  """
  def create_comment(thread, content_id, %Accounts.User{id: user_id}, body) do
    with {:ok, action} <- match_action(thread, :comment),
         {:ok, content} <- ORM.find(action.target, content_id),
         {:ok, user} <- ORM.find(Accounts.User, user_id) do
      nextFloor = get_next_floor(thread, action.reactor, content.id)

      attrs = %{
        author_id: user.id,
        body: body,
        floor: nextFloor
      }

      attrs = merge_comment_attrs(thread, attrs, content.id)

      action.reactor |> ORM.create(attrs)
    end
  end

  defp merge_comment_attrs(:post, attrs, id), do: attrs |> Map.merge(%{post_id: id})
  defp merge_comment_attrs(:job, attrs, id), do: attrs |> Map.merge(%{job_id: id})

  @doc """
  Delete the comment and increase all the floor after this comment
  """
  def delete_comment(thread, content_id) do
    with {:ok, action} <- match_action(thread, :comment),
         {:ok, comment} <- ORM.find(action.reactor, content_id) do
      case ORM.delete(comment) do
        {:ok, comment} ->
          Repo.update_all(
            from(p in action.reactor, where: p.id > ^comment.id),
            inc: [floor: -1]
          )

          {:ok, comment}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  def list_comments(thread, content_id, %{page: page, size: size} = filters) do
    with {:ok, action} <- match_action(thread, :comment) do
      dynamic = dynamic_comment_where(thread, content_id)

      action.reactor
      |> where(^dynamic)
      |> QueryBuilder.filter_pack(filters)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  def list_replies(thread, comment_id, %Accounts.User{id: user_id}) do
    with {:ok, action} <- match_action(thread, :comment) do
      action.reactor
      |> where([c], c.author_id == ^user_id)
      |> join(:inner, [c], r in assoc(c, :reply_to))
      |> where([c, r], r.id == ^comment_id)
      |> Repo.all()
      |> done()
    end
  end

  def reply_comment(thread, comment_id, %Accounts.User{id: user_id}, body) do
    with {:ok, action} <- match_action(thread, :comment),
         {:ok, comment} <- ORM.find(action.reactor, comment_id) do
      nextFloor = get_next_floor(thread, action.reactor, comment)

      attrs = %{
        author_id: user_id,
        body: body,
        reply_to: comment,
        floor: nextFloor
      }

      attrs = merge_reply_attrs(thread, attrs, comment)
      brige_reply(thread, action.reactor, comment, attrs)
    end
  end

  defp merge_reply_attrs(:post, attrs, comment),
    do: attrs |> Map.merge(%{post_id: comment.post_id})

  defp merge_reply_attrs(:job, attrs, comment), do: attrs |> Map.merge(%{job_id: comment.job_id})

  defp brige_reply(:post, queryable, comment, attrs) do
    # TODO: use Multi task to refactor
    with {:ok, reply} <- ORM.create(queryable, attrs) do
      ORM.update(reply, %{reply_id: comment.id})

      {:ok, _} =
        PostCommentReply |> ORM.create(%{post_comment_id: comment.id, reply_id: reply.id})

      queryable |> ORM.find(reply.id)
    end
  end

  defp brige_reply(:job, queryable, comment, attrs) do
    # TODO: use Multi task to refactor
    with {:ok, reply} <- ORM.create(queryable, attrs) do
      ORM.update(reply, %{reply_id: comment.id})

      {:ok, _} = JobCommentReply |> ORM.create(%{job_comment_id: comment.id, reply_id: reply.id})

      queryable |> ORM.find(reply.id)
    end
  end

  # for create comment
  defp get_next_floor(thread, queryable, id) when is_integer(id) do
    dynamic = dynamic_comment_where(thread, id)

    queryable
    |> where(^dynamic)
    |> ORM.next_count()
  end

  defp dynamic_comment_where(:post, id), do: dynamic([c], c.post_id == ^id)
  defp dynamic_comment_where(:job, id), do: dynamic([c], c.job_id == ^id)

  # for reply comment
  defp get_next_floor(thread, queryable, comment) do
    dynamic = dynamic_reply_where(thread, comment)

    queryable
    |> where(^dynamic)
    |> ORM.next_count()
  end

  defp dynamic_reply_where(:post, comment), do: dynamic([c], c.post_id == ^comment.post_id)
  defp dynamic_reply_where(:job, comment), do: dynamic([c], c.job_id == ^comment.job_id)
end
