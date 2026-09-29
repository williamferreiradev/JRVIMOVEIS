import { serverSupabaseUser } from '#supabase/server'

export const requireUserAdmin = async (event: Parameters<typeof serverSupabaseUser>[0]) => {
  const user = await serverSupabaseUser(event)

  if (!user) {
    throw createError({ statusCode: 401, statusMessage: 'Sessão não autenticada' })
  }

  const allowedEmails = (process.env.ADMIN_EMAILS || '')
    .split(',')
    .map(email => email.trim().toLowerCase())
    .filter(Boolean)

  if (!user.email || !allowedEmails.includes(user.email.toLowerCase())) {
    throw createError({ statusCode: 403, statusMessage: 'Acesso restrito a administradores' })
  }

  return user
}
