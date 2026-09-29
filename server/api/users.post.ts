import { serverSupabaseServiceRole, serverSupabaseUser } from '#supabase/server'

interface CreateUserBody {
  name?: string
  email?: string
  password?: string
}

export default defineEventHandler(async (event) => {
  const currentUser = await serverSupabaseUser(event)

  if (!currentUser) {
    throw createError({ statusCode: 401, statusMessage: 'Sessão não autenticada' })
  }

  const body = await readBody<CreateUserBody>(event)
  const name = body.name?.trim()
  const email = body.email?.trim().toLowerCase()
  const password = body.password || ''

  if (!name) {
    throw createError({ statusCode: 400, statusMessage: 'Informe o nome do usuário' })
  }

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw createError({ statusCode: 400, statusMessage: 'Informe um e-mail válido' })
  }

  if (password.length < 6) {
    throw createError({ statusCode: 400, statusMessage: 'A senha deve ter pelo menos 6 caracteres' })
  }

  const adminClient = serverSupabaseServiceRole(event)
  const { data, error } = await adminClient.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: name }
  })

  if (error) {
    const duplicate = error.message.toLowerCase().includes('already') || error.message.toLowerCase().includes('registered')
    throw createError({
      statusCode: duplicate ? 409 : 500,
      statusMessage: duplicate ? 'Já existe um usuário com este e-mail' : error.message
    })
  }

  return {
    user: {
      id: data.user.id,
      name,
      email: data.user.email || email,
      createdAt: data.user.created_at
    }
  }
})
