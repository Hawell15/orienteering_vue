function meta(name) {
  const el = document.querySelector(`meta[name="${name}"]`)
  return el ? el.getAttribute('content') : ''
}

export const isSignedIn = meta('user-signed-in') === 'true'
export const isAdmin = meta('user-is-admin') === 'true'
export const userEmail = meta('user-email')
export const signInPath = meta('sign-in-path') || '/users/sign_in'
export const signOutPath = meta('sign-out-path') || '/users/sign_out'
