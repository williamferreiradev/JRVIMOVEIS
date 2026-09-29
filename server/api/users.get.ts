import { serverSupabaseServiceRole, serverSupabaseUser } from '#supabase/server'

export default defineEventHandler(async (event) => {
  const currentUser = await serverSupabaseUser(event)

  if (!currentUser) {
    throw createError({ statusCode: 401, statusMessage: 'Sessão não autenticada' })
  }

  const adminClient = serverSupabaseServiceRole(event)
  const users = []
  let page = 1
  const perPage = 1000

  while (true) {
    const { data, error } = await adminClient.auth.admin.listUsers({ page, perPage })

    if (error) {
      throw createError({ statusCode: 500, statusMessage: error.message })
    }

    users.push(...data.users)

    if (data.users.length < perPage) break
    page += 1
  }

  return {
    users: users.map((user) => ({
      id: user.id,
      name: user.user_metadata?.full_name || user.user_metadata?.name || '',
      email: user.email || '',
      createdAt: user.created_at
    }))
  }
})
