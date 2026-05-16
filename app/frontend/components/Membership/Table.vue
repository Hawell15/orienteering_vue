<template>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('club_name')">Club</th>
                <th @click="orderTable('full_name')">Sportiv</th>
                <th @click="orderTable('results_count')">Rezultate</th>
                <th colspan="3">Acțiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`/memberships/${element.id}`">{{element.id}}</a></td>
                <td><a :href="`/clubs/${element.club_id}`">{{element.club_name}}</a></td>
                <td><a :href="`/runners/${element.runner_id}`">{{element.full_name}}</a></td>
                <td><a :href="`/results?membership_id=${element.id}`">{{element.results_count}}</a></td>
                <td><a class="btn btn-sm btn-warning" :href="`/memberships/${element.id}`"> Arată </a></td>
                <td><button class="btn btn-sm btn-success" @click="editElement(element)">Editează</button></td>
                <td><button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">Șterge</button></td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :membership="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
const props = defineProps({
    elements: Object
})

const emit = defineEmits(['order'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi această afiliere?')) {
        axios.delete(`/memberships/${id}`).then(() => {
            props.elements = props.elements.filter(membership => membership.id !== id)
        })
    }
}

function editElement(element) {
    modalElement.value = { ...element }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/memberships/${elementData.id}.json`, { membership: elementData }).then(res => {
        const index = props.elements.findIndex(c => c.id === res.data.id)
        if (index !== -1) props.elements[index] = { ...props.elements[index], ...res.data }
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}
</script>
