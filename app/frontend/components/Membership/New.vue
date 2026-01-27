<template>
    <MembershipModal ref="modal" :membership="modalMembership" :isNew="true" @save="saveMembership" />
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'
import MembershipModal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const modalMembership = ref({})
const modal = ref(null)

function createNew() {
    modal.value.show()
}

onMounted(() => {
    createNew()
})

function saveMembership(membershipData, done) {
    axios.post('/memberships.json', { membership: membershipData }).then(res => {
        window.location = "/memberships?sorting[direction]=desc";
    })
}
</script>
