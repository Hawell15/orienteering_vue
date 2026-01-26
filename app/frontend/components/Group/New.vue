<template>
    <GroupModal ref="modal" :group="modalGroup" :isNew="true" @save="saveGroup" />
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'
import GroupModal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const modalGroup = ref({})
const modal = ref(null)

function createNew() {
    modal.value.show()
}

onMounted(() => {
    createNew()
})

function saveGroup(groupData, done) {
    axios.post('/groups.json', { group: groupData }).then(res => {
        window.location = "/groups?sorting[direction]=desc";
    })
}
</script>
